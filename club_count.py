import os
import sqlite3
import logging
import pandas as pd

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "worldcup26.db")
XLSX_PATH = os.path.join(BASE_DIR, "club_count.xlsx")
LOG_PATH = os.path.join(BASE_DIR, "worldcup26.log")

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
            SELECT 
                club,
                COUNT(player_id) AS player_count
            FROM players
            GROUP BY club
            ORDER BY player_count DESC;
        """
        df = pd.read_sql(query, conn)
        df.to_excel(XLSX_PATH, index=False)
        logging.info(f"{len(df)} rows added to file.")
        return df
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    main()