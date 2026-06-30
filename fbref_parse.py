import os
import sys
import logging
import re
import pandas as pd
from bs4 import BeautifulSoup
from io import StringIO

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
LOG_PATH = os.path.join(BASE_DIR, "worldcup26.log")

PLAYER_COLS = ["Min", "Gls", "Ast", "PK", "PKatt", "Sh", "SoT", "CrdY", "CrdR", "Fls", "Fld", "Off", "Crs", "TklW", "Int", "OG", "PKwon", "PKcon"]
KEEPER_COLS = ["Min", "SoTA", "GA", "Saves"]

logging.basicConfig(
    filename=LOG_PATH,
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

def read_table(html_path):
    with open(html_path, "r", encoding="utf-8") as f:
        html = f.read()
    soup = BeautifulSoup(html, "lxml")
    player_tables = soup.find_all("table", id=re.compile(r"^stats_[0-9a-f]+_summary$"))
    keeper_tables = soup.find_all("table", id=re.compile(r"^keeper_stats_[0-9a-f]+$"))
    return player_tables, keeper_tables

def parse_table(table, team_id, match_id, numeric_cols):
    # Extract fbref_id from data-append-csv attribute before pd.read_html loses the HTML
    id_map = {}
    for tr in table.find("tbody").find_all("tr"):
        th = tr.find("th", {"data-stat": "player"})
        if th and th.get("data-append-csv"):
            id_map[th.get_text(strip=True)] = th["data-append-csv"]

    df = pd.read_html(StringIO(str(table)))[0]
    df.columns = df.columns.get_level_values(-1)
    df = df[df["Min"] != "Min"]
    df = df[~df["Player"].str.contains("Players", na=False)].copy()
    df[numeric_cols] = df[numeric_cols].apply(pd.to_numeric, errors="coerce").fillna(0).astype(int)
    df["fbref_id"] = df["Player"].map(id_map)   # stable join key — no name drift
    df["team_id"] = team_id
    df["match_id"] = match_id
    return df

def main():
    if len(sys.argv) < 2:
        logging.error("Usage: python3 fbref_parse.py <match_hex>")
        sys.exit(1)

    match_hex = sys.argv[1]
    html_path   = os.path.join(BASE_DIR, "results", "raw", f"{match_hex}.html")
    player_path = os.path.join(BASE_DIR, "results", f"{match_hex}_players.csv")
    keeper_path = os.path.join(BASE_DIR, "results", f"{match_hex}_keepers.csv")

    if not os.path.exists(html_path):
        logging.error(f"HTML not found for {match_hex}: {html_path}")
        sys.exit(1)

    player_tables, keeper_tables = read_table(html_path)

    players = []
    for t in player_tables:
        team_id = re.match(r"^stats_([0-9a-f]+)_summary$", t["id"]).group(1)
        df = parse_table(t, team_id, match_hex, PLAYER_COLS)
        players.append(df)
    player_df = pd.concat(players, ignore_index=True)
    player_df.to_csv(player_path, index=False)
    logging.info(f"{match_hex}: {len(player_df)} player rows written.")

    keepers = []
    for t in keeper_tables:
        team_id = re.match(r"^keeper_stats_([0-9a-f]+)$", t["id"]).group(1)
        df = parse_table(t, team_id, match_hex, KEEPER_COLS)
        keepers.append(df)
    keeper_df = pd.concat(keepers, ignore_index=True)
    keeper_df.to_csv(keeper_path, index=False)
    logging.info(f"{match_hex}: {len(keeper_df)} keeper rows written.")

if __name__ == "__main__":
    main()
