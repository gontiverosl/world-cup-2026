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

    print("\n--- VERIFY: live vs scratch rebuild (must be exact) ---")
    for name in DIGEST_QUERIES:
        status = "MISMATCH" if name in mismatches else "ok"
        print(f"  {name:18} {status}")

    print("\n--- VERIFY: monotonic floor (counts never decrease) ---")
    for name, floor in FLOOR.items():
        actual = live_counts[name]
        status = "BELOW FLOOR" if actual < floor else "ok"
        print(f"  {name:18} live={actual:<6} floor={floor:<6} {status}")

    if mismatches or below_floor:
        for name in mismatches:
            logging.error(f"verify: {name} differs between live and scratch rebuild.")
        for name, actual, floor in below_floor:
            logging.error(f"verify: {name}={actual} below floor {floor}.")
        print("\nVERIFY FAILED — investigate before trusting worldcup26_results.sql.")
        sys.exit(1)

    logging.info("verify: live == scratch rebuild, all counts at or above floor.")
    print("\nVERIFY PASSED — seed + results rebuilds live exactly.")


if __name__ == "__main__":
    main()
