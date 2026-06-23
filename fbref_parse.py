import os
import logging
import pandas as pd
from bs4 import BeautifulSoup
from io import StringIO

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
HTML_PATH = os.path.join(BASE_DIR, "results", "raw", "a2c54ed9.html")
LOG_PATH = os.path.join(BASE_DIR, "worldcup26.log")
CSV_PATH = os.path.join(BASE_DIR, "results", "a2c54ed9.csv")

logging.basicConfig(
    filename=LOG_PATH,
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

def main():
    with open(HTML_PATH, "r", encoding="utf-8") as f:
        html = f.read()
    soup = BeautifulSoup(html, "lxml")
    table = soup.find("table", {"id": "stats_c1e40422_summary"})
    df = pd.read_html(StringIO(str(table)))[0]
    df.columns = df.columns.get_level_values(-1)
    df = df.iloc[:-1]
    df = df[df["Min"] != "Min"]
    numeric_cols = ["Min", "Gls", "Ast", "PK", "PKatt", "Sh", "SoT", "CrdY", "CrdR", "Fls", "Fld", "Off", "Crs", "TklW", "Int", "OG", "PKwon", "PKcon"]
    df[numeric_cols] = df[numeric_cols].apply(pd.to_numeric, errors="coerce").fillna(0).astype(int)
    df.to_csv(CSV_PATH, index=False)
    logging.info(f"{len(df)} rows written to CSV.")

if __name__ == "__main__":
    main()