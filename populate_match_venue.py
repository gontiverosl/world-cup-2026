"""
populate_match_venue.py
Populates fifa_match_no, stadium, city in worldcup26.db matches table
using the 4 CSV files as source. Placeholder teams and the CUR→CUW
code discrepancy are resolved before matching.
"""

import csv
import logging
import os
import sqlite3

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH  = os.path.join(BASE_DIR, "worldcup26.db")
CSV_DIR  = BASE_DIR

# Placeholder and code corrections: CSV fifa_code → DB team_id
OVERRIDES = {
    "UEPD": "CZE",  # Group A — Czechia won UEFA Playoff D
    "UEPA": "BIH",  # Group B — Bosnia & Herz. won UEFA Playoff A
    "UEPC": "TUR",  # Group D — Türkiye won UEFA Playoff C
    "UEPB": "SWE",  # Group F — Sweden won UEFA Playoff B
    "FP02": "IRQ",  # Group I — Iraq won FIFA Playoff 2
    "FP01": "COD",  # Group K — DR Congo won FIFA Playoff 1
    "CUR":  "CUW",  # Curaçao: CSV uses currency code, DB uses ISO 3166
}


def load_csv_teams():
    """Returns dict: csv_id (str) → db_team_id (str)."""
    mapping = {}
    with open(os.path.join(CSV_DIR, "teams.csv")) as f:
        for row in csv.DictReader(f):
            code = row["fifa_code"]
            db_code = OVERRIDES.get(code, code)
            mapping[row["id"]] = db_code
    return mapping


def load_cities():
    """Returns dict: city_id (str) → (city_name, venue_name)."""
    cities = {}
    with open(os.path.join(CSV_DIR, "host_cities.csv")) as f:
        for row in csv.DictReader(f):
            cities[row["id"]] = (row["city_name"], row["venue_name"])
    return cities


def load_csv_matches(team_map, city_map):
    """
    Returns list of dicts with keys:
      match_no, home, away, city, stadium, match_date
    Only group stage (stage_id == 1).
    """
    records = []
    with open(os.path.join(CSV_DIR, "matches.csv")) as f:
        for row in csv.DictReader(f):
            if row["stage_id"] != "1":
                continue
            home_csv = row["home_team_id"]
            away_csv = row["away_team_id"]
            if not home_csv or not away_csv:
                continue
            home = team_map.get(home_csv)
            away = team_map.get(away_csv)
            if not home or not away:
                logging.warning("Unmapped team ids: home=%s away=%s", home_csv, away_csv)
                continue
            city_name, venue = city_map[row["city_id"]]
            # Extract date portion from "2026-06-11 15:00:00-06"
            match_date = row["kickoff_at"].split(" ")[0]
            records.append({
                "match_no":   int(row["match_number"]),
                "home":       home,
                "away":       away,
                "city":       city_name,
                "stadium":    venue,
                "match_date": match_date,
            })
    return records


def build_db_pair_index(cur):
    """Returns dict: frozenset({home, away}) → match_id."""
    cur.execute("SELECT match_id, team_home, team_away FROM matches WHERE stage = 'group'")
    return {frozenset([r[1], r[2]]): r[0] for r in cur.fetchall()}


def main():
    team_map  = load_csv_teams()
    city_map  = load_cities()
    csv_matches = load_csv_matches(team_map, city_map)
    logging.info("CSV group matches loaded: %d", len(csv_matches))

    conn = None
    try:
        conn = sqlite3.connect(DB_PATH)
        cur  = conn.cursor()
        pair_index = build_db_pair_index(cur)
        logging.info("DB group matches indexed: %d", len(pair_index))

        updated   = 0
        unmatched = []

        for m in csv_matches:
            pair = frozenset([m["home"], m["away"]])
            match_id = pair_index.get(pair)
            if match_id is None:
                unmatched.append(m)
                continue
            cur.execute(
                "UPDATE matches SET fifa_match_no=?, stadium=?, city=? WHERE match_id=?",
                (m["match_no"], m["stadium"], m["city"], match_id),
            )
            updated += 1

        conn.commit()
        logging.info("Updated:   %d rows", updated)

        if unmatched:
            logging.warning("Unmatched CSV rows (%d):", len(unmatched))
            for m in unmatched:
                logging.warning("  match_no=%d  %s vs %s  %s", m["match_no"], m["home"], m["away"], m["match_date"])
        else:
            logging.info("All CSV rows matched — no gaps.")

        # Verification: show sample of updated rows
        cur.execute("""
            SELECT m.fifa_match_no, t1.country, t2.country, m.city, m.stadium, m.match_date
            FROM matches m
            JOIN teams t1 ON m.team_home = t1.team_id
            JOIN teams t2 ON m.team_away = t2.team_id
            WHERE m.fifa_match_no IS NOT NULL
            ORDER BY m.fifa_match_no
            LIMIT 10
        """)
        print("\n{:<6} {:<22} {:<22} {:<25} {:<30} {}".format(
            "No.", "Home", "Away", "City", "Stadium", "Date"))
        print("-" * 115)
        for row in cur.fetchall():
            print("{:<6} {:<22} {:<22} {:<25} {:<30} {}".format(*row))

        # Check for any remaining NULLs
        cur.execute("SELECT COUNT(*) FROM matches WHERE stage='group' AND fifa_match_no IS NULL")
        nulls = cur.fetchone()[0]
        if nulls:
            logging.warning("%d group matches still have NULL fifa_match_no", nulls)
        else:
            logging.info("All group matches have fifa_match_no populated.")

    finally:
        if conn:
            conn.close()


if __name__ == "__main__":
    main()
