import os
import sqlite3
import logging
import pandas as pd

BASE_DIR = os.path.abspath(os.path.dirname(__file__))
DB_PATH = os.path.join(BASE_DIR, "worldcup26.db")
LOG_PATH = os.path.join(BASE_DIR, "worldcup26.log")
CSV_PATH = os.path.join(BASE_DIR, "results", "squad_counts.csv")

logging.basicConfig(
    filename=LOG_PATH,
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

def main():
    conn = None
    try:
        conn = sqlite3.connect(DB_PATH)
        query = """
            SELECT t.country, COUNT(p.player_id) AS player_count
            FROM teams t
            LEFT JOIN players p ON t.team_id = p.team_id
            GROUP BY t.team_id
            ORDER BY player_count DESC
        """
        df = pd.read_sql(query, conn)
        df.to_csv(CSV_PATH, index=False)
        logging.info(f"{len(df)} rows written to CSV.")
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    main()