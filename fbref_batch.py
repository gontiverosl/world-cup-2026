"""
fbref_batch.py — parse + load all match HTMLs that have been fetched but not yet loaded.

Usage:
    python3 fbref_batch.py

Expects HTML files at results/raw/{hex}.html (fetched separately via Chrome).
Skips any match where player_stats already has rows (idempotent).
"""
import os
import sys
import sqlite3
import logging
import subprocess

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH  = os.path.join(BASE_DIR, "worldcup26.db")
LOG_PATH = os.path.join(BASE_DIR, "worldcup26.log")
RAW_DIR  = os.path.join(BASE_DIR, "results", "raw")

logging.basicConfig(
    filename=LOG_PATH,
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

def get_pending_matches(conn):
    """Return list of match_hexes that have HTML on disk but no player_stats rows yet."""
    cur = conn.cursor()
    cur.execute("""
        SELECT m.fbref_match_id
        FROM matches m
        WHERE m.fbref_match_id IS NOT NULL
          AND NOT EXISTS (
              SELECT 1 FROM player_stats ps WHERE ps.match_id = m.match_id
          )
        ORDER BY m.match_date
    """)
    hexes = [row[0] for row in cur.fetchall()]
    # Only include those with HTML already on disk
    return [h for h in hexes if os.path.exists(os.path.join(RAW_DIR, f"{h}.html"))]

def run(cmd):
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        logging.error(f"Command failed: {' '.join(cmd)}\n{result.stderr}")
        return False
    return True

def main():
    conn = None
    try:
        conn = sqlite3.connect(DB_PATH)
        pending = get_pending_matches(conn)
    finally:
        if conn:
            conn.close()

    if not pending:
        print("Nothing to process — all fetched matches are already loaded.")
        logging.info("fbref_batch: nothing to process.")
        return

    print(f"{len(pending)} matches to parse + load.")
    loaded = 0
    failed = 0

    for hex_id in pending:
        print(f"  processing {hex_id}...", end=" ", flush=True)

        ok_parse = run([sys.executable, os.path.join(BASE_DIR, "fbref_parse.py"), hex_id])
        if not ok_parse:
            print("PARSE FAILED")
            failed += 1
            continue

        ok_load = run([sys.executable, os.path.join(BASE_DIR, "fbref_load.py"), hex_id])
        if not ok_load:
            print("LOAD FAILED")
            failed += 1
            continue

        print("ok")
        loaded += 1

    print(f"\nDone — {loaded} loaded, {failed} failed.")
    logging.info(f"fbref_batch: {loaded} loaded, {failed} failed.")

if __name__ == "__main__":
    main()
