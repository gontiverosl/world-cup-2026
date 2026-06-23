# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Project

World Cup 2026 (WC26) — a live SQLite database of the FIFA World Cup 2026 (Jun 11 – Jul 19, 2026), built and grown session by session. Phase 3 domain anchor (S4 slash commands + S5 skills — complete). Phase 4 data visualization capstone — comparable in scope to the CFDI Parser. Target: one or more LinkedIn posts built with Python, SQL, FastAPI, pandas, Plotly, and Tableau Public. The DB grows daily as match results come in.

## Database Schema

**worldcup26.db** (rebuilt from `worldcup26_seed.sql` + `worldcup26_results.sql`)
- `teams`: team_id (TEXT PK — 3-letter FIFA code), country (TEXT NOT NULL), confederation (TEXT NOT NULL), group_name (TEXT NOT NULL — 'A'–'L'), fifa_ranking (INTEGER), appearances (INTEGER — previous WC tournaments excl. WC26; 0 = first-timer), best_finish (TEXT — NULL for first-timers; values: 'Champion'/'Runner-up'/'Third place'/'Quarterfinals'/'Round of 16'/'Round of 32'/'Group stage'), coach (TEXT), host (INTEGER DEFAULT 0 — 1 = co-host MEX/USA/CAN), base_camp (TEXT — 'city, state, country'), market_value_m (REAL — Transfermarkt pre-tournament snapshot, EUR millions). All static.
- `players`: player_id (INTEGER PK AUTOINCREMENT), team_id (TEXT FK → teams.team_id), shirt_number (INTEGER), name (TEXT NOT NULL), position (TEXT NOT NULL — GK/DF/MF/FW; combos like FW-MF), footed (TEXT — 'Left'/'Right'), birthday (TEXT — 'YYYY-MM-DD'), birthplace (TEXT — 'city, state, country'), league (TEXT), club (TEXT), matches_played (INTEGER), matches_started (INTEGER), minutes_played (INTEGER), goals (INTEGER), assists (INTEGER), yellow_cards (INTEGER), red_cards (INTEGER). All static. Career NT stats (matches_played → red_cards) sourced from FBref national team pages, excluding WC26 data. Nullable until populated.
- `matches`: match_id (INTEGER PK AUTOINCREMENT), fifa_match_no (INTEGER UNIQUE), team_home (TEXT FK, NULL for unresolved knockout), team_away (TEXT FK, NULL for unresolved knockout), goals_home (INTEGER), goals_away (INTEGER), pk_home (INTEGER, NULL unless knockout + tied), pk_away (INTEGER, NULL unless knockout + tied), corners_home (INTEGER), corners_away (INTEGER), possession_home (REAL — % without sign), possession_away (REAL), stage (TEXT NOT NULL — 'group'/'r32'/'r16'/'qf'/'sf'/'third_place'/'final'), group_name (TEXT NOT NULL — 'A'–'L' for group stage, 'knock-out' for knockout), match_date (TEXT ISO 'YYYY-MM-DD'), match_time (TEXT 'HH:MM' local), stadium (TEXT), city (TEXT), attendance (INTEGER), referee (TEXT). Static fields: match_id, fifa_match_no, team_home/away (group fixed; knockout dynamic), stage, group_name, match_date, match_time, stadium, city. Dynamic fields (worldcup26_results.sql): goals_home/away, pk_home/away, corners_home/away, possession_home/away, attendance, referee.
- `player_stats`: stat_id (INTEGER PK AUTOINCREMENT), player_id (INTEGER FK → players.player_id), match_id (INTEGER FK → matches.match_id), minutes_played (Min), goals (Gls), assists (Ast), pk_made (G-PK), pk_att (PKatt), shots (Sh), shots_on_goal (SoT), yellow_cards (CrdY), red_cards (CrdR), fouls (Fls), fouls_drawn (Fld), offsides (Off), crosses (Crs), tackles_won (TklW), interceptions (Int), own_goals (OG), pk_won (PKwon), pk_conceded (PKcon) — all INTEGER DEFAULT 0. UNIQUE (player_id, match_id). Column order matches FBref Summary tab left-to-right. All dynamic — rows inserted via worldcup26_results.sql.
- `goalkeeper_stats`: stat_id (INTEGER PK AUTOINCREMENT), player_id (INTEGER FK → players.player_id), match_id (INTEGER FK → matches.match_id), minutes_played (INTEGER DEFAULT 0), shots_on_target_against (SoTA, INTEGER DEFAULT 0), goals_against (GA, INTEGER DEFAULT 0), saves (INTEGER DEFAULT 0). UNIQUE (player_id, match_id). Maps to FBref Goalkeeper Stats tab. save_pct is derived — never stored: CAST(saves AS REAL) / NULLIF(shots_on_target_against, 0). GK also appears in player_stats with outfield columns. All dynamic — rows inserted via worldcup26_results.sql.

## Stack

Python 3.14 · pandas · openpyxl · SQLite (stdlib + CLI) · FastAPI (planned: wc26_api.py) · Plotly (Phase 4 — EDA + export) · Tableau Public (Phase 4 — LinkedIn dashboards)

Rebuild DB:  `sqlite3 worldcup26.db < worldcup26_seed.sql && sqlite3 worldcup26.db < worldcup26_results.sql`
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
- `worldcup26_seed.sql` is the **pure structural baseline** — schema + reference data only. This includes teams, players, match schedule (with NULL goal placeholders), and the empty table definitions for `player_stats` / `goalkeeper_stats`. Never put scores or stat data here.
- Daily result updates source: https://fbref.com/en/comps/1/2026/matches. The `daily-update` scheduled task (cron `0 0 * * *`) is a reminder to: (1) UPDATE matches with result + corners + possession + attendance + referee; (2) INSERT player_stats from FBref Summary tab; (3) INSERT goalkeeper_stats from FBref Goalkeeper Stats tab; (4) append all statements to `worldcup26_results.sql`.
- **Dynamic field map** — `worldcup26_results.sql` contains exactly three statement types:
  - `UPDATE matches` — goals, pk, corners, possession, attendance, referee (post-match); team_home/team_away (knockout bracket, pre-match)
  - `INSERT INTO player_stats` — one row per player per match, all stat columns
  - `INSERT INTO goalkeeper_stats` — one row per GK per match, all stat columns
  - `teams` and `players` have no dynamic fields — never appear in worldcup26_results.sql
- **Score update rule**: match scores go into `worldcup26_results.sql` as `UPDATE` statements — never into `worldcup26_seed.sql`. Apply the same UPDATE to the live DB and append it to `worldcup26_results.sql`. The seed holds NULL goals as structural placeholders; rebuilding from seed intentionally wipes all scores.
- **Knockout team assignment rule**: once knockout teams are known, run `UPDATE matches SET team_home=?, team_away=? WHERE match_id=?` against the live DB and append to `worldcup26_results.sql`. Only update the seed when correcting structural data (wrong bracket position, wrong date).
- **Results layer rule**: `worldcup26_results.sql` accumulates **all** dynamic data — match score UPDATEs and player/GK stat INSERTs. Rebuild = `sqlite3 worldcup26.db < worldcup26_seed.sql && sqlite3 worldcup26.db < worldcup26_results.sql`. This file is the "final seed" for the LinkedIn-ready repo.
- **Canonical data source**: https://fbref.com/en/ — all player stats and match data come from FBref. Summary tab → `player_stats`. Goalkeeper Stats tab → `goalkeeper_stats`. Never INSERT or UPDATE from memory — always verify against FBref first.

## Prohibited (never do)

- No f-strings or string concatenation in SQL queries
- No `import *`
- No `print()` as the only error signal in pipeline code — use `logging` (formatted table printing for human-facing reports is fine)
- No `SUM() OVER (PARTITION BY)` inside aggregation CTEs — causes duplicate rows in SQLite
- No `RANK()` in output that goes to humans — use `DENSE_RANK()`
- No editing `worldcup26.db` schema directly — change `worldcup26_seed.sql` and rebuild
- No hallucinated match results. Always verify on FBref if a match has been played before any UPDATE or INSERT.

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

### Session discipline (commit ritual)

A session is **not done until git is clean.** Commit is part of "done," not an optional afterthought.

- **No session ends with uncommitted work.** Flow-state work — schema redesigns, architecture spikes, the Sunday rabbit holes — is exactly what skips the commit. It's also the most valuable work to not lose. Close it out.
- **`wip:` commits are allowed and encouraged mid-flow.** `git commit -m "wip: schema redesign spike"` beats zero commits. Squash later if you care. A messy paper trail beats no paper trail.
- **One trigger, not five steps.** Use `/wrap <prefix>` to collapse diff → stage → commit → push into a single command (drill spec: `learn-claude/Drill_Spec_Wrap_Command_v1.md`).
- **The Sunday Reflection checks this repo's `git status` + last-commit age** — the backstop that catches a multi-day uncommitted backlog before it grows. (See `learn-claude/Learning_OS.md` §11.)

## File layout

```
world-cup-2026/
├── worldcup26.db            — SQLite database (live, grows daily, tracked in git)
├── worldcup26_seed.sql      — pure structural baseline (schema + reference data + NULL score placeholders)
├── worldcup26_results.sql   — dynamic data accumulator (match score UPDATEs + player/GK stat INSERTs)
├── wc26_standings.py        — group standings from played matches
├── CLAUDE.md                — this file
├── results/                 — match result CSVs as the tournament progresses
├── .claude/
│   ├── commands/            — slash commands (S4)
│   └── skills/              — domain knowledge files (always-on context)
└── [session files]          — wc26_report.py, wc26_api.py, wc26_loader.py (planned)
```