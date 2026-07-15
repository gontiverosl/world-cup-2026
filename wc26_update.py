"""
wc26_update.py — the UPD node: one script owns the results layer.

Replaces the June improvisation (fbref_batch.py + generate_inserts.py + hand-edits).

    ACQUIRE → PARSE → LOAD → metadata → REGENERATE → VERIFY

ACQUIRE/PARSE/LOAD are incremental (only matches not yet loaded).
REGENERATE + VERIFY always run full, from complete live DB state — even when zero
matches were acquired, because live may have changed by other means (e.g. a manual
knockout bracket UPDATE).

Failure policy: any node failure (scrape error, parse miss, unresolved id) skips that
match and logs it. Never partial-applies, never estimates.

Usage:
    python3 wc26_update.py                       # regen + verify only
    python3 wc26_update.py <url-or-hex> ...      # acquire those, then load + regen + verify
"""
import os
import sys
import logging
import sqlite3
import subprocess
from datetime import datetime, timezone

import fbref_parse

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "worldcup26.db")
RAW_DIR = os.path.join(BASE_DIR, "results", "raw")
LOG_PATH = os.path.join(BASE_DIR, "worldcup26.log")

logging.basicConfig(
    filename=LOG_PATH,
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

# A WC26 match has exactly two teams, so a valid page yields two summary tables and
# two keeper tables. Anything less means a truncated/blocked fetch — item 6: that's a
# MATCH failure, not a half-load. Loading one team's stats would look like the other
# team simply didn't play.
EXPECTED_TABLES_PER_MATCH = 2

PENDING_QUERY = """
    SELECT m.fbref_match_id
    FROM matches m
    WHERE m.fbref_match_id IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM player_stats ps WHERE ps.match_id = m.match_id
      )
    ORDER BY m.match_date
"""


def run(cmd):
    """Run a pipeline step as a subprocess. Returns True on success."""
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        logging.error(f"Command failed: {' '.join(cmd)}\n{result.stderr}")
        return False
    return True


def get_pending_matches(conn):
    """Matches with HTML on disk but no player_stats rows yet — resumable by construction."""
    hexes = [row[0] for row in conn.execute(PENDING_QUERY)]
    return [h for h in hexes if os.path.exists(os.path.join(RAW_DIR, f"{h}.html"))]


def check_atomicity(match_hex):
    """Guard the whole-match rule before anything touches the DB."""
    html_path = os.path.join(RAW_DIR, f"{match_hex}.html")
    player_tables, keeper_tables = fbref_parse.read_table(html_path)
    if (len(player_tables) < EXPECTED_TABLES_PER_MATCH
            or len(keeper_tables) < EXPECTED_TABLES_PER_MATCH):
        logging.error(
            f"{match_hex}: found {len(player_tables)} summary / {len(keeper_tables)} keeper "
            f"tables, expected {EXPECTED_TABLES_PER_MATCH} each — match skipped, not half-loaded."
        )
        return False
    return True


def write_metadata(db_path):
    """Owner of the three task-owned metadata fields. wc26_regenerate.py is a pure
    serializer, so the live row must be correct BEFORE regen — that also keeps the
    regenerated file byte-identical across runs (no clock inside the serializer)."""
    conn = None
    try:
        conn = sqlite3.connect(db_path)
        last_matchday = conn.execute(
            "SELECT MAX(match_date) FROM matches WHERE goals_home IS NOT NULL"
        ).fetchone()[0]
        # Snapshot semantics: total stat rows now present. The old "this-run delta"
        # definition is meaningless once every run rewrites the whole file.
        records_imported = (
            conn.execute("SELECT COUNT(*) FROM player_stats").fetchone()[0]
            + conn.execute("SELECT COUNT(*) FROM goalkeeper_stats").fetchone()[0]
        )
        last_sync = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        conn.execute(
            "UPDATE metadata SET last_sync = ?, last_matchday = ?, records_imported = ?",
            (last_sync, last_matchday, records_imported),
        )
        conn.commit()
        logging.info(
            f"metadata: last_sync={last_sync}, last_matchday={last_matchday}, "
            f"records_imported={records_imported}"
        )
        return last_sync, last_matchday, records_imported
    finally:
        if conn:
            conn.close()


def acquire(sources):
    """Fetch any requested pages not already on disk. Returns False if any fetch failed."""
    if not sources:
        return True
    print(f"ACQUIRE — {len(sources)} source(s)")
    return run([sys.executable, os.path.join(BASE_DIR, "fbref_acquire.py"), *sources])


def load_pending():
    """PARSE + LOAD every acquired-but-unloaded match. Returns (loaded, failed)."""
    conn = None
    try:
        conn = sqlite3.connect(DB_PATH)
        pending = get_pending_matches(conn)
    finally:
        if conn:
            conn.close()

    if not pending:
        print("PARSE/LOAD — nothing pending; all acquired matches already loaded.")
        return 0, 0

    print(f"PARSE/LOAD — {len(pending)} pending match(es)")
    loaded, failed = 0, 0
    for match_hex in pending:
        print(f"  {match_hex}:", end=" ", flush=True)

        if not check_atomicity(match_hex):
            print("SKIPPED (incomplete tables — see log)")
            failed += 1
            continue
        if not run([sys.executable, os.path.join(BASE_DIR, "fbref_parse.py"), match_hex]):
            print("PARSE FAILED")
            failed += 1
            continue
        if not run([sys.executable, os.path.join(BASE_DIR, "fbref_load.py"), match_hex]):
            print("LOAD FAILED")
            failed += 1
            continue

        print("loaded")
        loaded += 1
    return loaded, failed


def main():
    sources = sys.argv[1:]

    if not acquire(sources):
        print("\nACQUIRE reported failures — continuing with whatever landed on disk.")

    loaded, failed = load_pending()

    last_sync, last_matchday, records = write_metadata(DB_PATH)
    print(f"METADATA — last_sync={last_sync}, last_matchday={last_matchday}, "
          f"records_imported={records}")

    print("REGENERATE —", end=" ", flush=True)
    if not run([sys.executable, os.path.join(BASE_DIR, "wc26_regenerate.py")]):
        print("FAILED — see worldcup26.log")
        sys.exit(1)
    print("worldcup26_results.sql rewritten from live DB")

    # Streamed, not captured — the rebuild check is the point of the run, so its
    # table belongs on screen. It rebuilds a scratch DB, so run it exactly once.
    # Flush first: VERIFY writes to this stdout directly, and when ours is a pipe
    # (block-buffered) our earlier prints would otherwise surface after its output.
    sys.stdout.flush()
    verify = subprocess.run([sys.executable, os.path.join(BASE_DIR, "wc26_verify.py")])
    ok_verify = verify.returncode == 0

    print(f"\nDone — {loaded} match(es) loaded, {failed} failed.")
    logging.info(f"wc26_update: {loaded} loaded, {failed} failed, verify_ok={ok_verify}")
    if not ok_verify or failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
