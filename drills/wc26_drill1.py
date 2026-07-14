import os
import sqlite3
import pandas as pd

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "worldcup26.db")

def main():
    conn = None
    try:
        conn = sqlite3.connect(DB_PATH)
        df = pd.read_sql("SELECT * FROM players", conn)
        df["age_group"] = "Prime"
        df.loc[df["age"] < 23, "age_group"] = "U23"
        df.loc[df["age"] >= 30, "age_group"] = "Veteran"
        print(df)
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    main()