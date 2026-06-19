# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Project

World Cup 2026 (WC26) — a live SQLite database of the FIFA World Cup 2026 (Jun 11 – Jul 19, 2026), built and grown session by session. Learning/build project running parallel to NovaPay; it is the domain anchor for Phase 3 S4 (slash commands) + S5 (skills). Pure SQLite + Python stack — no new libraries. The DB grows daily as match results come in.

## Database Schema

**worldcup26.db** (rebuilt from `worldcup26_seed.sql`)
- `teams`: team_id (TEXT PK — 3-letter FIFA code), country (TEXT), confederation (TEXT), group_name (TEXT 'A'–'L'), fifa_ranking (INTEGER), coach (TEXT), host (INTEGER DEFAULT 0), squad_size (INTEGER), avg_age (REAL), market_value_m (REAL), base_camp (TEXT — "City, State/Province")
- `players`: player_id (INTEGER PK AUTOINCREMENT), team_id (TEXT FK → teams.team_id), name (TEXT), position (TEXT GK/DF/MF/FW), age (INTEGER), club (TEXT), caps (INTEGER DEFAULT 0), intl_goals (INTEGER DEFAULT 0)
- `matches`: match_id (INTEGER PK AUTOINCREMENT), fifa_match_no (INTEGER UNIQUE), team_home (TEXT FK, NULL for unresolved knockout), team_away (TEXT FK, NULL for unresolved knockout), goals_home (INTEGER), goals_away (INTEGER), stage (TEXT — 'group'/'r32'/'r16'/'qf'/'sf'/'third_place'/'final'), group_name (TEXT, NULL for knockout), match_date (TEXT ISO 'YYYY-MM-DD'), stadium (TEXT), city (TEXT)
- `player_stats`: stat_id (INTEGER PK AUTOINCREMENT), player_id (INTEGER FK → players.player_id), match_id (INTEGER FK → matches.match_id), goals (INTEGER DEFAULT 0), assists (INTEGER DEFAULT 0), minutes_played (INTEGER DEFAULT 0), yellow_cards (INTEGER DEFAULT 0), red_cards (INTEGER DEFAULT 0), shots (INTEGER DEFAULT 0), shots_on_goal (INTEGER DEFAULT 0), fouls (INTEGER DEFAULT 0). UNIQUE (player_id, match_id). Schema in worldcup26_seed.sql — table not yet populated.

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
- Daily result updates during the tournament = one `UPDATE matches SET goals_home=?, goals_away=? WHERE match_id=?` per result. The `daily-update` scheduled task runs at 12:00 AM (cron `0 0 * * *`).
- **Score update rule**: match scores go **directly into the live DB only** via `UPDATE` — never into `worldcup26_seed.sql`. The seed holds `NULL` goals for all matches as the structural baseline. Rebuilding from seed intentionally wipes all recorded scores.
- **Knockout team assignment rule**: once knockout teams are known, run `UPDATE matches SET team_home=?, team_away=? WHERE match_id=?` directly against the live DB. Only update the seed when correcting structural data (wrong bracket position, wrong date).

## Prohibited (never do)

- No f-strings or string concatenation in SQL queries
- No `import *`
- No `print()` as the only error signal in pipeline code — use `logging` (formatted table printing for human-facing reports is fine)
- No `SUM() OVER (PARTITION BY)` inside aggregation CTEs — causes duplicate rows in SQLite
- No `RANK()` in output that goes to humans — use `DENSE_RANK()`
- No editing `worldcup26.db` schema directly — change `worldcup26_seed.sql` and rebuild
- No hallucinated match results. Always verify if game has already been pleayed before updating tables.

## Learning Protocol (drills & sessions)

This is a **learning project**. Claude's job is to teach, not to build.

- **Never write drill code.** Give the spec → German writes cold → he runs it → Claude reviews.
- **Step by step, line by line.** When explaining or reviewing, go one concept at a time. Do not dump a full solution.
- **Never run the drill yourself.** Do not execute scripts on his behalf to prove they work.
- **Never mark a drill done.** He marks his own progress in the spaced-rep tracker after he has written and run it himself.
- **Only exception:** scaffolding that isn't the drill target (e.g., creating the results/ folder or seed CSV so he has data to work with).

## Quality bar

No hallucinated match results. Always verify if a game has already been played before updating tables. A standings table or leaderboard you'd be comfortable publishing. If you wouldn't trust the number, verify the data before touching the query.

## Skills

Domain knowledge files — always read these before writing code or queries:

@.claude/skills/python-hardening.md
@.claude/skills/worldcup-sql-report.md

## Git workflow

Run at the end of every session and anytime a working feature is complete.

```bash
git diff                        # review all changes before staging
git add <specific files>        # never git add . — stage intentionally
git commit -m "s5: description" # prefix with session or feature name
git push
```

- `git diff` first, always — same discipline as reviewing a plan before approving
- Stage specific files, not everything — avoids committing stale exports or scratch files
- `.gitignore` covers `*.log`, `__pycache__/` — worldcup26.db IS tracked (live data)
- Never `git push --force`

## File layout

```
world-cup-2026/
├── worldcup26.db            — SQLite database (live, grows daily, tracked in git)
├── worldcup26_seed.sql      — seed / version-control baseline
├── wc26_standings.py        — group standings from played matches
├── CLAUDE.md                — this file
├── results/                 — match result CSVs as the tournament progresses
├── .claude/
│   ├── commands/            — slash commands (S4)
│   └── skills/              — domain knowledge files (always-on context)
└── [session files]          — wc26_report.py, wc26_api.py, wc26_loader.py (planned)
```