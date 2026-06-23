import os
import sqlite3
import logging
import csv
import pandas as pd

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "worldcup26.db")
LOG_PATH = os.path.join(BASE_DIR, "worldcup26.log")
OUTPUT_PATH = os.path.join(BASE_DIR, "results", "top_scorers.csv")

logging.basicConfig(
    filename=LOG_PATH,
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

def export_top_scorers():
    conn = None
    try:
        conn = sqlite3.connect(DB_PATH)
        query = """
            WITH rank AS (
                SELECT
                    p.name,
                    t.country,
                    p.intl_goals,
                    DENSE_RANK() OVER (ORDER BY p.intl_goals DESC) AS intl_rank
                FROM teams t
                JOIN players p ON p.team_id = t.team_id
            )
            SELECT *
            FROM rank
            WHERE intl_rank <= 10;
        """
        df = pd.read_sql(query, conn)
        logging.info(f"{len(df)} lines loaded.")
        df.to_csv(OUTPUT_PATH, index=False)
        logging.info(f"{len(df)} lines exported to CSV.")
        return df
    finally:
        if conn:
            conn.close()

def load_top_scorers():
    top_scorers = []
    with open(OUTPUT_PATH, "r", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            top_scorers.append(row)
        logging.info(f"{len(top_scorers)} lines loaded.")
    return top_scorers

def main():
    df = export_top_scorers()
    top_scorers = load_top_scorers()
    for row in top_scorers:
        print(row["name"], row["intl_goals"])

if __name__ == "__main__":
    main()