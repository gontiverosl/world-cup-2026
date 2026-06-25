import os
import sqlite3
import logging
import pandas as pd

BASE_DIR = os.path.abspath(os.path.dirname(__file__))
DB_PATH = os.path.join(BASE_DIR, "worldcup26.db")
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
                name,
                position,
                birthday
            FROM players
        """
        df = pd.read_sql(query, conn)
        today = pd.Timestamp("2026-06-24")
        df["birthday"] = pd.to_datetime(df["birthday"])
        df["age"] = (today - df["birthday"]).dt.days // 365.25
        df.loc[df["age"] < 23, "age_group"] = "U23"
        df.loc[df["age"].between(23, 29), "age_group"] = "Prime"
        df.loc[df["age"] >= 30, "age_group"] = "Veteran"
        grouped_df = df[["name", "position", "age", "age_group"]]
        print(grouped_df.head(10))
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    main()