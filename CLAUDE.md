# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Project

World Cup 2026 (WC26) — a live SQLite database of the FIFA World Cup 2026 (Jun 11 – Jul 19, 2026), built and grown session by session. Learning/build project running parallel to NovaPay; it is the domain anchor for Phase 3 S4 (slash commands) + S5 (skills). Pure SQLite + Python stack — no new libraries. The DB grows daily as match results come in.

## Database Schema

**worldcup26.db** (rebuilt from `worldcup26_seed.sql`)
- `teams`: team_id (TEXT PK — 3-letter FIFA code), country (TEXT), confederation (TEXT), group_name (TEXT 'A'–'L'), fifa_ranking (INTEGER), coach (TEXT), host (INTEGER DEFAULT 0)
- `players`: player_id (INTEGER PK AUTOINCREMENT), team_id (TEXT FK → teams.team_id), name (TEXT), position (TEXT GK/DF/MF/FW), age (INTEGER), club (TEXT), caps (INTEGER DEFAULT 0), intl_goals (INTEGER DEFAULT 0)
- `matches`: match_id (INTEGER PK AUTOINCREMENT), team_home (TEXT FK), team_away (TEXT FK), goals_home (INTEGER), goals_away (INTEGER), stage (TEXT), group_name (TEXT, NULL for knockout), match_date (TEXT ISO 'YYYY-MM-DD')
- `player_stats` (planned, Phase 2): player_id FK, match_id FK, goals, assists, minutes_played, yellow_cards, red_cards

## Stack

Python 3.14 · pandas · openpyxl · SQLite (stdlib + CLI) · FastAPI (planned: wc26_api.py)

Rebuild DB:  `sqlite3 worldcup26.db < worldcup26_seed.sql`
Run script:  `python3 wc26_standings.py`
SQLite CLI:  `sqlite3 worldcup26.db`

## Conventions (always do)

Inherits the NovaPay conventions — keep them identical across both repos:

- `os.path` portable paths — `BASE_DIR = os.path.dirname(os.path.abspath(__file__))`
- `try/finally` for all DB connections — `conn = None` before try, `if conn: conn.close()` in finally
- `?` placeholders in all SQL — never f-strings or string concatenation in queries
- `conn.commit()` on every INSERT / UPDATE / DELETE
- `DENSE_RANK()` not `RANK()` — leaderboards go to humans, no gaps
- `SUM() + GROUP BY` in aggregation CTEs — not `SUM() OVER (PARTITION BY)`
- `logging.basicConfig()` at module level — log after result exists
- `if __name__ == "__main__":` guard on every script
- `pd.read_sql(query, conn)` — query first, connection second

## WC26-specific rules

- `goals_home` / `goals_away` are NULL when a match is **not yet played**. Standings and stats queries must filter `WHERE goals_home IS NOT NULL`.
- `matches` stores `team_id` references, never country names — JOIN to `teams` for display names.
- `worldcup26_seed.sql` is the **version-control baseline**. Schema changes go there first, then rebuild the DB. New full squads get added to the seed too — not just the live DB.
- Daily result updates during the tournament = one `UPDATE matches SET goals_home=?, goals_away=? WHERE match_id=?` per result. The `daily-update` scheduled task runs at 4:00 PM Monterrey.

## Prohibited (never do)

- No f-strings or string concatenation in SQL queries
- No `import *`
- No `print()` as the only error signal in pipeline code — use `logging` (formatted table printing for human-facing reports is fine)
- No `SUM() OVER (PARTITION BY)` inside aggregation CTEs — causes duplicate rows in SQLite
- No `RANK()` in output that goes to humans — use `DENSE_RANK()`
- No editing `worldcup26.db` schema directly — change `worldcup26_seed.sql` and rebuild

## Quality bar

Tournament-accurate and CFO-ready. A standings table or leaderboard you'd be comfortable publishing. If you wouldn't trust the number, verify the data before touching the query.

## File layout

```
world-cup-2026/
├── worldcup26.db            — SQLite database (live, grows daily, tracked in git)
├── worldcup26_seed.sql      — seed / version-control baseline
├── wc26_standings.py        — group standings from played matches
├── CLAUDE.md                — this file
├── results/                 — match result CSVs as the tournament progresses
└── [session files]          — wc26_report.py, wc26_api.py, wc26_loader.py (planned)
```
