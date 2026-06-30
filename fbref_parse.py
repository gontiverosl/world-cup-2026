import os
import logging
import re
import pandas as pd
from bs4 import BeautifulSoup
from io import StringIO

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
HTML_PATH = os.path.join(BASE_DIR, "results", "raw", "a2c54ed9.html")
LOG_PATH = os.path.join(BASE_DIR, "worldcup26.log")
PLAYER_PATH = os.path.join(BASE_DIR, "results", "a2c54ed9_players.csv")
KEEPER_PATH = os.path.join(BASE_DIR, "results", "a2c54ed9_keepers.csv")

MATCH_ID = "a2c54ed9"
PLAYER_COLS = ["Min", "Gls", "Ast", "PK", "PKatt", "Sh", "SoT", "CrdY", "CrdR", "Fls", "Fld", "Off", "Crs", "TklW", "Int", "OG", "PKwon", "PKcon"]
KEEPER_COLS = ["Min", "SoTA", "GA", "Saves"]

logging.basicConfig(
    filename=LOG_PATH,
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

def read_table(path):
    with open(path, "r", encoding="utf-8") as f:
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
    player_tables, keeper_tables = read_table(HTML_PATH)
    players = []
    for t in player_tables:
        team_id = re.match(r"^stats_([0-9a-f]+)_summary$", t["id"]).group(1)
        df = parse_table(t, team_id, MATCH_ID, PLAYER_COLS)
        players.append(df)
    player_df = pd.concat(players, ignore_index=True)
    player_df.to_csv(PLAYER_PATH, index=False)
    logging.info(f"{len(player_df)} player rows written.")
    keepers = []
    for t in keeper_tables:
        team_id = re.match(r"^keeper_stats_([0-9a-f]+)$", t["id"]).group(1)
        df = parse_table(t, team_id, MATCH_ID, KEEPER_COLS)
        keepers.append(df)
    keeper_df = pd.concat(keepers, ignore_index=True)
    keeper_df.to_csv(KEEPER_PATH, index=False)
    logging.info(f"{len(keeper_df)} keeper rows written.")

if __name__ == "__main__":
    main()