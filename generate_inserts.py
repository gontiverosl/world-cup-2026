import os
import sqlite3
import logging
import pandas as pd

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
LOG_PATH = os.path.join(BASE_DIR, "worldcup26.log")
DB_PATH = os.path.join(BASE_DIR, "worldcup26.db")
SQL_PATH = os.path.join(BASE_DIR, "worldcup26_results.sql")

logging.basicConfig(
    filename=LOG_PATH,
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

# stat_id is AUTOINCREMENT — omit it so the DB assigns it on rebuild
PLAYER_COLS = [
    "player_id", "match_id", "minutes_played", "goals", "assists",
    "pk_made", "pk_att", "shots", "shots_on_goal", "yellow_cards",
    "red_cards", "fouls", "fouls_drawn", "offsides", "crosses",
    "tackles_won", "interceptions", "own_goals", "pk_won", "pk_conceded"
]

KEEPER_COLS = [
    "player_id", "match_id", "minutes_played",
    "shots_on_target_against", "goals_against", "saves"
]

def make_insert(table, cols, row):
    """Build one INSERT OR REPLACE statement from a DataFrame row."""
    col_str = ", ".join(cols)
    # All stat columns are integers — cast explicitly to avoid float notation (e.g. 2.0)
    vals = ", ".join(str(int(row[c])) for c in cols)
    return f"INSERT OR REPLACE INTO {table} ({col_str}) VALUES ({vals});"

def main():
    conn = None
    try:
        conn = sqlite3.connect(DB_PATH)
        player_df = pd.read_sql("SELECT * FROM player_stats WHERE match_id = 25", conn)
        keeper_df  = pd.read_sql("SELECT * FROM goalkeeper_stats WHERE match_id = 25", conn)
    finally:
        if conn:
            conn.close()

    statements = []
    for _, row in player_df.iterrows():
        statements.append(make_insert("player_stats", PLAYER_COLS, row))
    for _, row in keeper_df.iterrows():
        statements.append(make_insert("goalkeeper_stats", KEEPER_COLS, row))

    with open(SQL_PATH, "a", encoding="utf-8") as f:
        f.write("\n-- match 25 (a2c54ed9 GER vs CUW): player_stats + goalkeeper_stats\n")
        for stmt in statements:
            f.write(stmt + "\n")

    logging.info(
        f"generate_inserts: {len(statements)} INSERT statements appended to worldcup26_results.sql."
    )

if __name__ == "__main__":
    main()
