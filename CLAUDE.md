# CLAUDE.md — world-cup-2026

Guidance for Claude Code working in this repository.

## Operating model

- **Claude Code lives in this repo** — executes, commits, tests, ships.
- **Claude Cowork lives in brain** (`C:\Users\gonti\brain`) — plans, reviews, orchestrates.
- **Germán steers the wheel.**
- **Claude Code never edits brain vault files — ever.** Brain is read-only context; all vault edits come from Cowork or Germán.

| | repo files | vault files | repo git | vault git |
|---|---|---|---|---|
| Claude Code | read/write | read only | commit/push | never |
| Claude Cowork | read only | read/write | read only | read only |
| Germán | all | all | all | sole committer (Obsidian Git plugin) |

**Handoff:** Cowork drafts repo files → session outputs → Germán places and commits from Code. Repo-writing automations run as Claude Code (`claude -p`), never as Cowork.

## Project

World Cup 2026 (WC26) — a live SQLite database of the FIFA World Cup 2026 (Jun 11 – Jul 19, 2026), built and grown session by session. Phase 4 data-visualization capstone. Target: LinkedIn posts built with Python, SQL, FastAPI, pandas, Plotly, and Tableau Public. The DB grows daily as match results come in.

**State at S7 kickoff:** schema frozen (v1.0.0, S6 closed 2026-07-08, rebuild check 8/8). S7 = results script + migrating player/GK stats acquisition to Firecrawl.

Project hub: `building/world-cup-2026/WC26 Main.md` in brain — status, roadmap, cross-project links. **This file is the truth for schema and conventions; the hub is the truth for status and roadmap. Never duplicate one into the other.**

## Database schema

**worldcup26.db** — rebuilt from `worldcup26_seed.sql` + `worldcup26_results.sql`.

- `teams`: team_id (TEXT PK — 3-letter FIFA code), fbref_team_id (TEXT UNIQUE — FBref squad-page hex), country (TEXT NOT NULL), confederation (TEXT NOT NULL), group_name (TEXT NOT NULL — 'A'–'L'), fifa_ranking (INTEGER), appearances (INTEGER — previous WCs; 0 = first-timer), best_finish (TEXT — NULL for first-timers; 'Champion'/'Runner-up'/'Third place'/'Fourth place'/'Quarterfinals'/'Round of 16'/'Round of 32'/'Group stage'), coach (TEXT), host (INTEGER DEFAULT 0 — 1 = MEX/USA/CAN), base_camp (TEXT — 'city, state, country'), market_value_m (REAL — Transfermarkt pre-tournament snapshot, EUR millions). All static.
- `players`: player_id (INTEGER PK AUTOINCREMENT), fbref_id (TEXT UNIQUE — FBref player id, stable join key), team_id (TEXT FK → teams), shirt_number (INTEGER), name (TEXT NOT NULL, indexed), position (TEXT NOT NULL — GK/DF/MF/FW; combos like FW-MF), goalkeeper_flag (INTEGER DEFAULT 0 — derived from `position LIKE '%GK%'`, seeded once), birthday (TEXT 'YYYY-MM-DD'), birthplace (TEXT — 'city, state, country'), league (TEXT), club (TEXT), matches_played, matches_started, minutes_played, goals, assists, yellow_cards, red_cards (all INTEGER — career NT stats from FBref national-team pages, excluding WC26; nullable until populated). All static.
- `matches`: match_id (INTEGER PK AUTOINCREMENT), fbref_match_id (TEXT UNIQUE — FBref match hex, pipeline join key), fifa_match_no (INTEGER UNIQUE), team_home (TEXT FK, NULL for unresolved knockout), team_away (TEXT FK, NULL for unresolved knockout), goals_home, goals_away (INTEGER), pk_home, pk_away (INTEGER, NULL unless knockout + tied), corners_home, corners_away (INTEGER), possession_home, possession_away (REAL — % without sign), stage (TEXT NOT NULL — 'group'/'r32'/'r16'/'qf'/'sf'/'third_place'/'final'), group_name (TEXT NOT NULL — 'A'–'L' for group stage, 'knock-out' otherwise), match_date (TEXT ISO), match_time (TEXT 'HH:MM' local), stadium, city (TEXT), attendance (INTEGER), referee (TEXT). Static: ids, teams (group fixed; knockout dynamic), stage, group_name, date/time, stadium, city. Dynamic (via results.sql): goals, pk, corners, possession, attendance, referee.
- `player_stats`: stat_id (INTEGER PK AUTOINCREMENT), player_id (FK), match_id (FK, indexed), minutes_played (Min), goals (Gls), assists (Ast), pk_made (G-PK), pk_att (PKatt), shots (Sh), shots_on_goal (SoT), yellow_cards (CrdY), red_cards (CrdR), fouls (Fls), fouls_drawn (Fld), offsides (Off), crosses (Crs), tackles_won (TklW), interceptions (Int), own_goals (OG), pk_won (PKwon), pk_conceded (PKcon) — all INTEGER DEFAULT 0. UNIQUE (player_id, match_id). Column order = FBref Summary tab left-to-right. All dynamic.
- `goalkeeper_stats`: stat_id (INTEGER PK AUTOINCREMENT), player_id (FK), match_id (FK), minutes_played, shots_on_target_against (SoTA), goals_against (GA), saves — all INTEGER DEFAULT 0. UNIQUE (player_id, match_id). Maps to FBref Goalkeeper Stats tab. save_pct is derived, never stored: `CAST(saves AS REAL) / NULLIF(shots_on_target_against, 0)`. GKs also appear in player_stats. All dynamic.
- `metadata`: singleton (one row, updated in place — no PK). Field ownership:

  | Field | Owner | Updated | Notes |
  |---|---|---|---|
  | `schema_version` | Human, seed-authored | Only on schema changes | Bump when seed `CREATE TABLE`s change |
  | `api_version` | Human, seed-authored | Only on API changes | NULL until `wc26_api.py` ships |
  | `last_sync` | `wc26-daily-update` task | Every run | ISO 8601 timestamp, not a bare date |
  | `last_matchday` | `wc26-daily-update` task | Every run | `MAX(match_date)` among played matches |
  | `records_imported` | `wc26-daily-update` task | Every run | **This-run delta**, never cumulative |

## Stack

Python 3.14 · pandas · openpyxl · SQLite (stdlib + CLI) · FastAPI (planned: `wc26_api.py`) · Plotly (EDA + export) · Tableau Public (LinkedIn dashboards)

```
Rebuild DB:  sqlite3 worldcup26.db < worldcup26_seed.sql && sqlite3 worldcup26.db < worldcup26_results.sql
Run script:  python3 wc26_standings.py
SQLite CLI:  sqlite3 worldcup26.db
```

## Conventions (always do)

Shared base — keep identical across all repos:

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

**Two-file data model:**
- `worldcup26_seed.sql` = pure structural baseline — schema + reference data + NULL score placeholders. Never scores or stats. Seed edits only for structural corrections (wrong bracket position, wrong date, schema change).
- `worldcup26_results.sql` = accumulates **all** dynamic data; exactly three statement types: `UPDATE matches` (goals/pk/corners/possession/attendance/referee post-match; team_home/away for knockout brackets pre-match), `INSERT INTO player_stats`, `INSERT INTO goalkeeper_stats`. `teams` and `players` never appear here.
- Every dynamic change: apply to the live DB **and** append to results.sql — always both. Rebuild = seed then results; rebuilding intentionally wipes and replays all dynamic data.

**Query rules:**
- `goals_home`/`goals_away` are NULL until played — standings and stats queries filter `WHERE goals_home IS NOT NULL`.
- `matches` stores `team_id` refs, never country names — JOIN `teams` for display.

**Source of truth:**
- Canonical source: https://fbref.com — Summary tab → `player_stats`, Goalkeeper Stats tab → `goalkeeper_stats`, schedule page → results. **Never INSERT or UPDATE from memory** — verify on FBref first, including whether a match has been played.

## Acquisition (FBref × Cloudflare)

**Never `requests`/`curl`/`httpx`** — FBref 403s all script access. **Firecrawl MCP is the production fetch method.**

- **Match results — working, migrating:** handled by the external `wc26-daily-update` scheduled skill (Cowork, cron `0 0 * * *`) via `firecrawl_scrape` JSON extraction. It UPDATEs `matches` (result, corners, possession, attendance, referee) + appends to results.sql + maintains `metadata`. It does **not** load player/GK stats. Migrating to a Claude Code systemd timer on the Merry per the permission matrix — see `Drill_Spec_Merry_Daily_Update` in brain; the Cowork task stays live until cutover.
- **Player/GK stats — broken, S7 scope:** this repo's acquire step was Chrome-saved HTML → `results/raw/`; Chrome was uninstalled 2026-07-08. **S7 migrates acquire to Firecrawl.** No `requests`-based workarounds in the meantime. Guard against Firecrawl LLM-extraction hallucination — prefer deterministic extraction (raw HTML / links format + regex) where possible.

## Data integrity invariants (never violate)

**Squad cap:** every `team_id` has exactly 26 `players` rows AND `shirt_number` forms a complete, gapless, non-duplicated 1–26 set:
```sql
SELECT team_id, COUNT(*) AS n, COUNT(DISTINCT shirt_number) AS distinct_n
FROM players GROUP BY team_id
HAVING n != 26 OR distinct_n != 26
```
must return zero rows. Row count alone is insufficient (a non-squad player can occupy a real slot). Never trust a source to have enforced this — FBref squad pages have returned 27–56 rows per squad. Check every player-adding fetch against the cap.

**Verification scales to change scale — do not over-apply:**
- Schema changes, bulk backfills, anything touching table structure → full rebuild-and-verify (scratch DB, row counts, invariant checks) is mandatory.
- Single targeted fixes (one row, one or two columns) → a scoped `SELECT ... WHERE ...` confirming the change. A full rebuild for a 1-row fix costs time for no added safety.

**Never overlap writes on the live DB:** `sqlite3` rebuild/apply commands run sequentially, each fully waited-on. Concurrent writes corrupt the binary mid-transaction (happened 2026-07-08). Recovery = one clean sequential rebuild from seed+results, never parallel fix attempts.

## FBref pipeline (stats layer)

Fills `player_stats`/`goalkeeper_stats`. Four layers — acquire is the only one that touches the network; everything downstream is local and idempotent.

```
1. ACQUIRE  ⚠ S7 rebuild target (was Chrome → results/raw/{hex}.html; broken 2026-07-08)
            fbref_urls.py  — URL/hex registry from the FBref schedule page
2. PARSE    fbref_parse.py {hex} → results/{hex}_players.csv + {hex}_keepers.csv
            Finds ALL stats_*_summary + keeper_stats_* tables (both teams, regex on table id).
            Extracts fbref_id from data-append-csv BEFORE read_html; stamps team_id + hex on every row.
3. LOAD     fbref_load.py {hex} → INSERT OR REPLACE into player_stats + goalkeeper_stats (live DB)
            fbref_batch.py — parse+load every match acquired but not yet loaded (resumable)
4. MIRROR   generate_inserts.py — exports stat rows as INSERT OR IGNORE, appends to results.sql
            ⚠ run ONCE per batch — re-running duplicates lines in the .sql
```

- **Identity resolution — never join on names.** Players resolve via `players.fbref_id`; matches via `matches.fbref_match_id` (URL hex; `fbref_map_matches.py` populates it, SLUG_TO_CODE for non-obvious codes). Name joins broke on accent drift. A missing crosswalk row = load skipped + logged, never a wrong id.
- **Idempotency:** loader is `INSERT OR REPLACE` (FBref revises stats post-match; stat_id churn is harmless). The results.sql mirror is `INSERT OR IGNORE`.
- **Standing verification (after every batch):** rebuild seed+results into a scratch DB, compare row counts (`matches` played, `player_stats`, `goalkeeper_stats`) against live. Catches both lockstep failure modes: stats loaded without score UPDATEs, and results.sql UPDATEs never applied live.
- **After each stats batch:** `UPDATE metadata SET last_sync=…, last_matchday=…, records_imported=…` in live DB + append to results.sql.

## Prohibited (never do)

- No f-strings or string concatenation in SQL queries
- No `import *`
- No `print()` as the only error signal in pipeline code — use `logging` (formatted tables for human-facing reports are fine)
- No `SUM() OVER (PARTITION BY)` inside aggregation CTEs — duplicate rows in SQLite
- No `RANK()` in human-facing output — use `DENSE_RANK()`
- No editing `worldcup26.db` schema directly — change the seed and rebuild
- No hallucinated match results — verify on FBref before any UPDATE or INSERT. If you wouldn't trust the number, verify before touching the query.

## Learning protocol (drills & sessions)

This is a **learning project**. Claude's job is to teach, not to build.

- **Never write drill code.** Spec → German writes cold → he runs it → Claude reviews.
- **Step by step, line by line** when explaining or reviewing — no full-solution dumps.
- **Never run the drill yourself.** Do not execute scripts on his behalf to prove they work.
- **Never mark a drill done.** He marks his own progress in the Learning Tracker after writing and running it himself.
- **Only exception:** scaffolding that isn't the drill target (e.g., a results/ folder or seed CSV).
- **Cowork staging rule:** code Claude writes in Cowork counts as 🌱 Exposure — he observed it, not produced it. Reproduction requires a cold write in a Claude Code session. Never award Reproduction from a Cowork-built script.

## Skills

Domain knowledge — always read before writing code or queries:

@.claude/skills/python-hardening.md
@.claude/skills/worldcup-sql-report.md

## Git workflow

- **Policy:** public GitHub remote; `worldcup26.db` IS tracked (live data); push at session end — registered in brain `Repos.md`.
- `git diff` first, always. Stage specific files — never `git add .`. Commit prefixed `s<N>:` / `wip:`. Never `git push --force`. `.gitignore` covers `*.log`, `__pycache__/`.
- **A session is not done until git is clean.** `wip:` commits are encouraged mid-flow — a messy paper trail beats no paper trail. `/wrap <prefix>` collapses diff → stage → commit → push.
- `/wrap` ends by **printing the session's drift summary** — Germán or a Cowork session logs it in brain `Repos.md` (Code never writes to the vault). The Sunday Reflection checks this repo's `git status` + last-commit age as the backstop.

## File layout

```
world-cup-2026/
├── worldcup26.db            — SQLite database (live, grows daily, tracked in git)
├── worldcup26_seed.sql      — pure structural baseline (schema + reference data + NULL placeholders)
├── worldcup26_results.sql   — dynamic data accumulator (score UPDATEs + stat INSERTs)
├── fbref_urls.py            — FBref match URL/hex registry
├── fbref_fetch.py           — dead reference (requests → 403; kept to document why)
├── fbref_move.py            — dead (Chrome-era Downloads/ mover; retire or repurpose in S7)
├── fbref_parse.py           — raw HTML → per-match players/keepers CSVs
├── fbref_load.py            — CSVs → player_stats + goalkeeper_stats
├── fbref_batch.py           — parse+load all acquired-but-unloaded matches
├── fbref_map_matches.py     — populates matches.fbref_match_id from URL slugs
├── generate_inserts.py      — mirrors stat rows into worldcup26_results.sql
├── wc26_standings.py        — group standings from played matches
├── wc26_viz.py              — Plotly viz (money vs goals scatter)
├── CLAUDE.md                — this file
├── results/                 — per-match CSVs; results/raw/ = acquired HTML (S7: Firecrawl)
├── .claude/
│   ├── commands/            — slash commands (/wrap lives here)
│   └── skills/              — domain knowledge files
└── [session files]          — wc26_report.py, wc26_api.py (planned)
```
