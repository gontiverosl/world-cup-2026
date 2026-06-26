import os
import sqlite3
import logging
import pandas as pd

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "worldcup26.db")
LOG_PATH = os.path.join(BASE_DIR, "worldcup26.log")
PLAYER_PATH = os.path.join(BASE_DIR, "results", "a2c54ed9_players.csv")
KEEPER_PATH = os.path.join(BASE_DIR, "results", "a2c54ed9_keepers.csv")

MATCH_ID = 25                                          # a2c54ed9 → integer match_id (drill constant)
TEAM_MAP = {"c1e40422": "GER", "e0f5893a": "CUW"}      # FBref hex → FIFA code

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

def resolve_player_id(conn, name, team_id):
    cursor = conn.cursor()
    cursor.execute("SELECT player_id FROM players WHERE name=? AND team_id=?", (name, team_id))
    row = cursor.fetchone()
    if row is None:
        logging.warning(f"No player_id for {name} ({team_id}) - skipped")
        return None 
    return row[0]

def load_players(conn, df, match_id):
    cursor = conn.cursor()
    inserted = 0
    for _, row in df.iterrows():
        team_id = TEAM_MAP[row["team_id"]]            # CSV hex → FIFA code
        pid = resolve_player_id(conn, row["Player"], team_id)
        if pid is None:
            continue                                  # miss already logged — skip
        values = (pid, match_id, row["Min"], row["Gls"], row["Ast"], row["PK"], row["PKatt"], row["Sh"], row["SoT"], row["CrdY"], row["CrdR"], row["Fls"], row["Fld"], row["Off"], row["Crs"], row["TklW"], row["Int"], row["OG"], row["PKwon"], row["PKcon"])
        cursor.execute(INSERT_PLAYER, values)
        inserted += 1
    logging.info(f"{inserted} player_stats rows inserted for match {match_id}.")

def load_keepers(conn, df, match_id):
    cursor = conn.cursor()
    inserted = 0
    for _, row in df.iterrows():
        team_id = TEAM_MAP[row["team_id"]]            # CSV hex → FIFA code
        pid = resolve_player_id(conn, row["Player"], team_id)
        if pid is None:
            continue                                  # miss already logged — skip
        values = (pid, match_id, row["Min"], row["SoTA"], row["GA"], row["Saves"])
        cursor.execute(INSERT_KEEPER, values)
        inserted += 1
    logging.info(f"{inserted} goalkeeper_stats rows inserted for match {match_id}.")

def main():
    conn = None
    try:
        conn = sqlite3.connect(DB_PATH)
        player_df = pd.read_csv(PLAYER_PATH)
        load_players(conn, player_df, MATCH_ID)
        keeper_df = pd.read_csv(KEEPER_PATH)
        load_keepers(conn, keeper_df, MATCH_ID)
        conn.commit()                                  # one commit covers both loaders
    finally:
        if conn:
            conn.close()
    
if __name__ == "__main__":
    main()