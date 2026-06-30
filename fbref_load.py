import os
import sys
import sqlite3
import logging
import pandas as pd

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "worldcup26.db")
LOG_PATH = os.path.join(BASE_DIR, "worldcup26.log")

# Idempotency: OR REPLACE keeps the DB in sync with the latest CSV on every re-run —
# FBref revises stats post-match, so a re-pull should overwrite, not skip.
# Trade-off: REPLACE = delete + insert, so the AUTOINCREMENT stat_id changes each run
# (harmless here — nothing references stat_id).

INSERT_PLAYER = """
    INSERT OR REPLACE INTO player_stats
        (player_id, match_id, minutes_played, goals, assists, pk_made, pk_att,
        shots, shots_on_goal, yellow_cards, red_cards, fouls, fouls_drawn,
        offsides, crosses, tackles_won, interceptions, own_goals, pk_won, pk_conceded)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
"""

INSERT_KEEPER = """
    INSERT OR REPLACE INTO goalkeeper_stats
        (player_id, match_id, minutes_played, shots_on_target_against, goals_against, saves)
    VALUES (?, ?, ?, ?, ?, ?)
"""

logging.basicConfig(
    filename=LOG_PATH,
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

def resolve_match_id(conn, match_hex):
    """Look up the integer match_id from the FBref match hex stored in matches.fbref_match_id."""
    cursor = conn.cursor()
    cursor.execute("SELECT match_id FROM matches WHERE fbref_match_id = ?", (match_hex,))
    row = cursor.fetchone()
    if row is None:
        logging.error(f"No match_id found for fbref_match_id={match_hex} — populate matches.fbref_match_id first.")
        return None
    return row[0]

def resolve_player_id(conn, fbref_id):
    """Look up player_id by fbref_id — stable across name changes and accent drift."""
    cursor = conn.cursor()
    cursor.execute("SELECT player_id FROM players WHERE fbref_id = ?", (fbref_id,))
    row = cursor.fetchone()
    if row is None:
        logging.warning(f"No player_id for fbref_id={fbref_id} — skipped")
        return None
    return row[0]

def load_players(conn, df, match_id):
    cursor = conn.cursor()
    inserted = 0
    for _, row in df.iterrows():
        pid = resolve_player_id(conn, row["fbref_id"])
        if pid is None:
            continue
        values = (
            pid, match_id,
            row["Min"], row["Gls"], row["Ast"], row["PK"], row["PKatt"],
            row["Sh"], row["SoT"], row["CrdY"], row["CrdR"],
            row["Fls"], row["Fld"], row["Off"], row["Crs"],
            row["TklW"], row["Int"], row["OG"], row["PKwon"], row["PKcon"]
        )
        cursor.execute(INSERT_PLAYER, values)
        inserted += 1
    logging.info(f"{inserted} player_stats rows inserted for match {match_id}.")

def load_keepers(conn, df, match_id):
    cursor = conn.cursor()
    inserted = 0
    for _, row in df.iterrows():
        pid = resolve_player_id(conn, row["fbref_id"])
        if pid is None:
            continue
        values = (pid, match_id, row["Min"], row["SoTA"], row["GA"], row["Saves"])
        cursor.execute(INSERT_KEEPER, values)
        inserted += 1
    logging.info(f"{inserted} goalkeeper_stats rows inserted for match {match_id}.")

def main():
    if len(sys.argv) < 2:
        logging.error("Usage: python3 fbref_load.py <match_hex>")
        sys.exit(1)

    match_hex = sys.argv[1]
    player_path = os.path.join(BASE_DIR, "results", f"{match_hex}_players.csv")
    keeper_path  = os.path.join(BASE_DIR, "results", f"{match_hex}_keepers.csv")

    conn = None
    try:
        conn = sqlite3.connect(DB_PATH)

        match_id = resolve_match_id(conn, match_hex)
        if match_id is None:
            return

        player_df = pd.read_csv(player_path)
        load_players(conn, player_df, match_id)

        keeper_df = pd.read_csv(keeper_path)
        load_keepers(conn, keeper_df, match_id)

        conn.commit()
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    main()
