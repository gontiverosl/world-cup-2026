import sqlite3
import pandas as pd
import os
import logging

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "worldcup26.db")

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")


def load_matches(conn):
    """Load all played matches (goals not null) with full team names via JOIN."""
    query = """
        SELECT
            m.match_id,
            m.group_name,
            m.match_date,
            th.country AS home_country,
            ta.country AS away_country,
            m.team_home,
            m.team_away,
            m.goals_home,
            m.goals_away
        FROM matches m
        LEFT JOIN teams th ON m.team_home = th.team_id
        LEFT JOIN teams ta ON m.team_away = ta.team_id
        WHERE m.goals_home IS NOT NULL
        ORDER BY m.match_date, m.match_id
    """
    return pd.read_sql(query, conn)


def compute_standings(df_matches):
    """Compute W/D/L/GF/GA/GD/Pts for each team from played matches."""
    records = []

    for _, row in df_matches.iterrows():
        gh, ga = row["goals_home"], row["goals_away"]

        if gh > ga:
            h_pts, a_pts = 3, 0
            h_w, h_d, h_l = 1, 0, 0
            a_w, a_d, a_l = 0, 0, 1
        elif gh == ga:
            h_pts, a_pts = 1, 1
            h_w, h_d, h_l = 0, 1, 0
            a_w, a_d, a_l = 0, 1, 0
        else:
            h_pts, a_pts = 0, 3
            h_w, h_d, h_l = 0, 0, 1
            a_w, a_d, a_l = 1, 0, 0

        records.append({
            "group": row["group_name"],
            "team_id": row["team_home"],
            "country": row["home_country"],
            "played": 1,
            "w": h_w, "d": h_d, "l": h_l,
            "gf": gh, "ga": ga,
            "pts": h_pts,
        })
        records.append({
            "group": row["group_name"],
            "team_id": row["team_away"],
            "country": row["away_country"],
            "played": 1,
            "w": a_w, "d": a_d, "l": a_l,
            "gf": ga, "ga": gh,
            "pts": a_pts,
        })

    df = pd.DataFrame(records)
    df_standings = (
        df.groupby(["group", "team_id", "country"])[["played", "w", "d", "l", "gf", "ga", "pts"]]
        .sum()
        .reset_index()
    )
    df_standings["gd"] = df_standings["gf"] - df_standings["ga"]
    df_standings = df_standings.sort_values(
        ["group", "pts", "gd", "gf"], ascending=[True, False, False, False]
    )
    return df_standings


def print_standings(df_standings):
    """Print formatted standings table, grouped by group."""
    for group in sorted(df_standings["group"].unique()):
        print(f"\n{'=' * 52}")
        print(f"  GROUP {group}")
        print(f"{'=' * 52}")
        print(f"  {'Team':<22} {'P':>2} {'W':>2} {'D':>2} {'L':>2} {'GF':>3} {'GA':>3} {'GD':>4} {'Pts':>4}")
        print(f"  {'-' * 48}")
        for _, row in df_standings[df_standings["group"] == group].iterrows():
            print(
                f"  {row['country']:<22} "
                f"{int(row['played']):>2} "
                f"{int(row['w']):>2} "
                f"{int(row['d']):>2} "
                f"{int(row['l']):>2} "
                f"{int(row['gf']):>3} "
                f"{int(row['ga']):>3} "
                f"{int(row['gd']):>4} "
                f"{int(row['pts']):>4}"
            )


def main():
    conn = None
    try:
        conn = sqlite3.connect(DB_PATH)
        logging.info("Connected to worldcup26.db")
        df_matches = load_matches(conn)
        logging.info(f"Loaded {len(df_matches)} played match(es)")
        df_standings = compute_standings(df_matches)
        print_standings(df_standings)
    except Exception as e:
        logging.error(f"Error: {e}")
        raise
    finally:
        if conn:
            conn.close()


if __name__ == "__main__":
    main()
