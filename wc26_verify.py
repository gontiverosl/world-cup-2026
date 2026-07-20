"""
wc26_verify.py — VERIFY node: prove seed + results rebuilds the live DB exactly.

Rebuilds a throwaway scratch DB from worldcup26_seed.sql + worldcup26_results.sql
and diffs it against the live DB. Catches both lockstep failure modes: stats loaded
into live but never mirrored to results.sql, and results.sql UPDATEs never applied live.

Two distinct checks, deliberately different in kind:
  1. EQUALITY  — live vs scratch rebuild. Must be EXACT. Row counts alone miss value
                 drift, so every dynamic row is digested and compared.
  2. FLOOR     — the 2026-07-13 baseline is a MONOTONIC FLOOR (counts never decrease),
                 never an equality target: it goes stale the moment a match loads.
                 After the final (Jul 19) it becomes the fixed expected final counts.

Mismatch = loud failure + non-zero exit. Never trust the file on a mismatch.

Usage:
    python3 wc26_verify.py [--results PATH] [--scratch PATH]
"""
import os
import sys
import hashlib
import logging
import sqlite3
import subprocess
import tempfile

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "worldcup26.db")
SEED_SQL = os.path.join(BASE_DIR, "worldcup26_seed.sql")
RESULTS_SQL = os.path.join(BASE_DIR, "worldcup26_results.sql")
LOG_PATH = os.path.join(BASE_DIR, "worldcup26.log")

# Monotonic floor — baseline snapshot 2026-07-13. Counts may exceed these, never fall below.
FLOOR = {"player_stats": 2263, "goalkeeper_stats": 149, "matches_played": 100}

# stat_id is excluded everywhere: it's AUTOINCREMENT and churns under INSERT OR REPLACE.
# Comparing it would report false mismatches on a correct rebuild.
DIGEST_QUERIES = {
    "matches": """
        SELECT match_id, team_home, team_away, goals_home, goals_away,
               pk_home, pk_away, corners_home, corners_away,
               possession_home, possession_away, attendance, referee
        FROM matches ORDER BY match_id
    """,
    "player_stats": """
        SELECT player_id, match_id, minutes_played, goals, assists, pk_made, pk_att,
               shots, shots_on_goal, yellow_cards, red_cards, fouls, fouls_drawn,
               offsides, crosses, tackles_won, interceptions, own_goals, pk_won, pk_conceded
        FROM player_stats ORDER BY match_id, player_id
    """,
    "goalkeeper_stats": """
        SELECT player_id, match_id, minutes_played, shots_on_target_against,
               goals_against, saves
        FROM goalkeeper_stats ORDER BY match_id, player_id
    """,
    "metadata": "SELECT last_sync, last_matchday, records_imported FROM metadata",
}

COUNT_QUERIES = {
    "player_stats": "SELECT COUNT(*) FROM player_stats",
    "goalkeeper_stats": "SELECT COUNT(*) FROM goalkeeper_stats",
    "matches_played": "SELECT COUNT(*) FROM matches WHERE goals_home IS NOT NULL",
}

# Integrity invariants (S7b, 2026-07-20) — added after the stale-player_id attribution bug:
# group/early-R32 stats were loaded before the S6 26-cap renumber of `players`, so their
# player_id FKs pointed at the wrong people. EQUALITY only proves live == results.sql; it
# cannot see that a player_id is the WRONG person. These check truth, not reproducibility.
INTEGRITY_QUERIES = {
    # The check that catches the stale-FK class: every stat row's player must belong to one
    # of that match's two teams. A permutation conserves per-match sums (so goals-reconcile
    # alone would miss it), but membership cannot be permuted away.
    "player_team_membership": """
        SELECT ps.match_id, p.name, p.team_id
        FROM player_stats ps
        JOIN players p ON p.player_id = ps.player_id
        JOIN matches m ON m.match_id = ps.match_id
        WHERE p.team_id NOT IN (m.team_home, m.team_away)
    """,
    "keeper_team_membership": """
        SELECT gs.match_id, p.name, p.team_id
        FROM goalkeeper_stats gs
        JOIN players p ON p.player_id = gs.player_id
        JOIN matches m ON m.match_id = gs.match_id
        WHERE p.team_id NOT IN (m.team_home, m.team_away)
    """,
}

# Goals must reconcile to the scoreline, modulo own goals (FBref doesn't credit an OG to a
# scorer). A HAVING hit means a goal is attributed to no player in the DB.
# NB: HAVING repeats the aggregate expressions rather than reusing the SELECT aliases. A bare
# `own_goals` in HAVING would resolve to the raw player_stats.own_goals column (an arbitrary
# row of the group), NOT the SUM — SQLite binds the real column over the output alias. The
# alias is likewise named own_goal_total so it can never shadow the column downstream.
GOALS_RECONCILE_QUERY = """
    SELECT m.fifa_match_no,
           m.goals_home + m.goals_away   AS score,
           COALESCE(SUM(ps.goals), 0)    AS stat_goals,
           COALESCE(SUM(ps.own_goals),0) AS own_goal_total
    FROM matches m
    LEFT JOIN player_stats ps ON ps.match_id = m.match_id
    WHERE m.goals_home IS NOT NULL
    GROUP BY m.match_id
    HAVING (m.goals_home + m.goals_away - COALESCE(SUM(ps.goals), 0))
           != COALESCE(SUM(ps.own_goals), 0)
    ORDER BY m.fifa_match_no
"""

# Known, separately-tracked reconciliation gaps that are NOT attribution bugs, keyed by
# fifa_match_no. Match 15 (KSA 1-1 URU): scorer Abdulelah Al-Amri (fbref_id fd0affe3) is
# absent from `players` (a 26-cap roster gap), so LOAD drops his goal. Allowlisted so a
# REAL new reconciliation failure still fails loudly. Remove once the KSA squad is fixed.
KNOWN_GOAL_GAPS = {15}

logging.basicConfig(
    filename=LOG_PATH,
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)


def rebuild_scratch(scratch_path, seed_sql, results_sql):
    """seed then results, strictly sequential — concurrent sqlite3 writes corrupt the
    binary mid-transaction (happened 2026-07-08). Each command fully waited on."""
    if os.path.exists(scratch_path):
        os.remove(scratch_path)
    for sql_file in (seed_sql, results_sql):
        with open(sql_file, "r", encoding="utf-8") as f:
            result = subprocess.run(
                ["sqlite3", scratch_path],
                stdin=f, capture_output=True, text=True,
            )
        if result.returncode != 0:
            logging.error(f"verify: rebuild failed on {sql_file}: {result.stderr}")
            print(f"REBUILD FAILED on {os.path.basename(sql_file)}:\n{result.stderr}")
            return False
    return True


def digest(conn, query):
    """Stable hash of a result set — catches value drift that row counts miss."""
    h = hashlib.md5()
    for row in conn.execute(query):
        h.update(repr(row).encode("utf-8"))
        h.update(b"\x1e")
    return h.hexdigest()


def snapshot(db_path):
    conn = None
    try:
        conn = sqlite3.connect(db_path)
        digests = {name: digest(conn, q) for name, q in DIGEST_QUERIES.items()}
        counts = {name: conn.execute(q).fetchone()[0] for name, q in COUNT_QUERIES.items()}
        return digests, counts
    finally:
        if conn:
            conn.close()


def compare(live, scratch):
    """Exact equality, table by table. Returns list of mismatched table names."""
    return [name for name, live_hash in live.items() if scratch.get(name) != live_hash]


def check_floor(counts):
    """Returns list of (name, actual, floor) for any count that fell below the baseline."""
    return [(n, counts[n], f) for n, f in FLOOR.items() if counts[n] < f]


def check_truth(db_path):
    """Attribution invariants against the LIVE DB. Returns (membership, recon_rows):
    membership maps check name → list of offending rows; recon_rows are the goal-gap rows."""
    conn = None
    try:
        conn = sqlite3.connect(db_path)
        membership = {name: conn.execute(q).fetchall() for name, q in INTEGRITY_QUERIES.items()}
        recon_rows = conn.execute(GOALS_RECONCILE_QUERY).fetchall()
        return membership, recon_rows
    finally:
        if conn:
            conn.close()


def main():
    results_sql = RESULTS_SQL
    if "--results" in sys.argv:
        results_sql = sys.argv[sys.argv.index("--results") + 1]

    if "--scratch" in sys.argv:
        scratch_path = sys.argv[sys.argv.index("--scratch") + 1]
    else:
        scratch_path = os.path.join(tempfile.gettempdir(), "wc26_scratch.db")

    if not rebuild_scratch(scratch_path, SEED_SQL, results_sql):
        sys.exit(1)

    live_digests, live_counts = snapshot(DB_PATH)
    scratch_digests, _ = snapshot(scratch_path)

    mismatches = compare(live_digests, scratch_digests)
    below_floor = check_floor(live_counts)

    membership, recon_rows = check_truth(DB_PATH)
    recon_blocking = [r for r in recon_rows if r[0] not in KNOWN_GOAL_GAPS]
    recon_known = [r for r in recon_rows if r[0] in KNOWN_GOAL_GAPS]
    membership_bad = {name: rows for name, rows in membership.items() if rows}

    print("\n--- VERIFY: live vs scratch rebuild (must be exact) ---")
    for name in DIGEST_QUERIES:
        status = "MISMATCH" if name in mismatches else "ok"
        print(f"  {name:18} {status}")

    print("\n--- VERIFY: monotonic floor (counts never decrease) ---")
    for name, floor in FLOOR.items():
        actual = live_counts[name]
        status = "BELOW FLOOR" if actual < floor else "ok"
        print(f"  {name:18} live={actual:<6} floor={floor:<6} {status}")

    print("\n--- VERIFY: attribution integrity (truth, not reproducibility) ---")
    for name in INTEGRITY_QUERIES:
        rows = membership.get(name, [])
        status = "ok" if not rows else f"{len(rows)} FOREIGN ROW(S)"
        print(f"  {name:24} {status}")
    recon_status = "ok" if not recon_blocking else f"{len(recon_blocking)} UNEXPLAINED"
    print(f"  {'goals_reconcile':24} {recon_status}")
    for fno, score, sg, og in recon_known:
        print(f"    known gap (allowlisted): match {fno} score={score} stat_goals={sg} own_goals={og}")

    if mismatches or below_floor or membership_bad or recon_blocking:
        for name in mismatches:
            logging.error(f"verify: {name} differs between live and scratch rebuild.")
        for name, actual, floor in below_floor:
            logging.error(f"verify: {name}={actual} below floor {floor}.")
        for name, rows in membership_bad.items():
            logging.error(f"verify: {name} — {len(rows)} stat row(s) belong to a non-match team.")
        for fno, score, sg, og in recon_blocking:
            logging.error(f"verify: match {fno} goals do not reconcile: score={score} stat={sg} og={og}.")
        print("\nVERIFY FAILED — investigate before trusting worldcup26_results.sql.")
        sys.exit(1)

    logging.info("verify: live == scratch rebuild, counts at/above floor, attribution integrity ok.")
    print("\nVERIFY PASSED — seed + results rebuilds live exactly.")


if __name__ == "__main__":
    main()
