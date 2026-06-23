import csv
import logging
import os
import sqlite3

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "worldcup26.db")
RESULTS_DIR = os.path.join(BASE_DIR, "results")

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")


# ── 1. File discovery ──────────────────────────────────────────────────────────

def find_result_csvs(results_dir):
    """Return sorted list of .csv paths in results_dir. Empty list if dir missing."""
    if not os.path.isdir(results_dir):
        logging.warning("results/ directory not found: %s", results_dir)
        return []
    paths = sorted(
        os.path.join(results_dir, f)
        for f in os.listdir(results_dir)
        if f.endswith(".csv")
    )
    logging.info("Found %d result file(s) in %s", len(paths), results_dir)
    return paths


# ── 2. CSV reading ─────────────────────────────────────────────────────────────

def load_csv(path):
    """Read a results CSV. Returns list of dicts with match_id, goals_home, goals_away."""
    rows = []
    with open(path, newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append({
                "match_id":   int(row["match_id"]),
                "goals_home": int(row["goals_home"]),
                "goals_away": int(row["goals_away"]),
            })
    logging.info("Loaded %d row(s) from %s", len(rows), os.path.basename(path))
    return rows


# ── 3. DB write ────────────────────────────────────────────────────────────────

def update_match(conn, match_id, goals_home, goals_away):
    """UPDATE a single match result. Returns True if a row was affected."""
    query = """
        UPDATE matches
        SET goals_home = ?, goals_away = ?
        WHERE match_id = ?
    """
    cursor = conn.cursor()
    cursor.execute(query, (goals_home, goals_away, match_id))
    conn.commit()
    if cursor.rowcount == 0:
        logging.warning("match_id=%d not found — skipped", match_id)
        return False
    logging.info("Updated match_id=%d → %d-%d", match_id, goals_home, goals_away)
    return True


# ── 4. File processor ──────────────────────────────────────────────────────────

def process_file(conn, path):
    """Load one CSV and push each result to the DB. Returns (updated, skipped) counts."""
    rows = load_csv(path)
    updated = skipped = 0
    for row in rows:
        ok = update_match(conn, row["match_id"], row["goals_home"], row["goals_away"])
        if ok:
            updated += 1
        else:
            skipped += 1
    return updated, skipped


# ── 5. Orchestrator ────────────────────────────────────────────────────────────

def main():
    paths = find_result_csvs(RESULTS_DIR)
    if not paths:
        logging.warning("No CSV files to process — exiting")
        return

    conn = None
    try:
        conn = sqlite3.connect(DB_PATH)
        total_updated = total_skipped = 0

        for path in paths:
            updated, skipped = process_file(conn, path)
            total_updated += updated
            total_skipped += skipped

        logging.info(
            "Done — %d match(es) updated, %d skipped across %d file(s)",
            total_updated, total_skipped, len(paths),
        )
    finally:
        if conn:
            conn.close()


if __name__ == "__main__":
    main()
