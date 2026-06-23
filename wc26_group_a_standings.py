import os
import sqlite3
import logging

import pandas as pd

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "worldcup26.db")

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

GROUP = "A"

QUERY = """
WITH played AS (
    SELECT team_home AS team,
           CASE WHEN goals_home > goals_away THEN 3
                WHEN goals_home = goals_away THEN 1 ELSE 0 END AS pts,
           goals_home AS gf, goals_away AS ga,
           CASE WHEN goals_home > goals_away THEN 1 ELSE 0 END AS w,
           CASE WHEN goals_home = goals_away THEN 1 ELSE 0 END AS d,
           CASE WHEN goals_home < goals_away THEN 1 ELSE 0 END AS l
    FROM matches
    WHERE goals_home IS NOT NULL AND group_name = ?
    UNION ALL
    SELECT team_away,
           CASE WHEN goals_away > goals_home THEN 3
                WHEN goals_home = goals_away THEN 1 ELSE 0 END,
           goals_away, goals_home,
           CASE WHEN goals_away > goals_home THEN 1 ELSE 0 END,
           CASE WHEN goals_home = goals_away THEN 1 ELSE 0 END,
           CASE WHEN goals_away < goals_home THEN 1 ELSE 0 END
    FROM matches
    WHERE goals_home IS NOT NULL AND group_name = ?
)
SELECT t.country,
       COUNT(*)              AS played,
       SUM(p.w)              AS w,
       SUM(p.d)              AS d,
       SUM(p.l)              AS l,
       SUM(p.gf)             AS gf,
       SUM(p.ga)             AS ga,
       SUM(p.gf) - SUM(p.ga) AS gd,
       SUM(p.pts)            AS pts
FROM played p
JOIN teams t ON p.team = t.team_id
GROUP BY p.team
ORDER BY pts DESC, gd DESC, gf DESC, t.country ASC;
"""

ALL_TEAMS_QUERY = """
SELECT country FROM teams WHERE group_name = ? ORDER BY country ASC;
"""


def main():
    conn = None
    try:
        conn = sqlite3.connect(DB_PATH)
        standings = pd.read_sql(QUERY, conn, params=(GROUP, GROUP))
        all_teams = pd.read_sql(ALL_TEAMS_QUERY, conn, params=(GROUP,))
    finally:
        if conn:
            conn.close()

    logging.info("Built Group %s standings: %d team(s) with played matches", GROUP, len(standings))

    if standings.empty:
        print(f"Group {GROUP} standings — no matches played yet.\n")
        header = f"{'Team':<15}{'P':>3}{'W':>3}{'D':>3}{'L':>3}{'GF':>4}{'GA':>4}{'GD':>4}{'Pts':>5}"
        print(header)
        print("-" * len(header))
        for country in all_teams["country"]:
            print(f"{country:<15}{0:>3}{0:>3}{0:>3}{0:>3}{0:>4}{0:>4}{0:>4}{0:>5}")
        return

    played_teams = set(standings["country"])
    missing = [c for c in all_teams["country"] if c not in played_teams]

    print(f"Group {GROUP} Standings\n")
    header = f"{'Team':<15}{'P':>3}{'W':>3}{'D':>3}{'L':>3}{'GF':>4}{'GA':>4}{'GD':>4}{'Pts':>5}"
    print(header)
    print("-" * len(header))
    for _, row in standings.iterrows():
        gd = f"{row['gd']:+d}" if row['gd'] != 0 else "0"
        print(f"{row['country']:<15}{row['played']:>3}{row['w']:>3}{row['d']:>3}{row['l']:>3}"
              f"{row['gf']:>4}{row['ga']:>4}{gd:>4}{row['pts']:>5}")
    for country in missing:
        print(f"{country:<15}{0:>3}{0:>3}{0:>3}{0:>3}{0:>4}{0:>4}{0:>4}{0:>5}")


if __name__ == "__main__":
    main()
