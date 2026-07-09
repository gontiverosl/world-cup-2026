# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Project

World Cup 2026 (WC26) — a live SQLite database of the FIFA World Cup 2026 (Jun 11 – Jul 19, 2026), built and grown session by session. Phase 3 domain anchor (S4 slash commands + S5 skills — complete). Phase 4 data visualization capstone — comparable in scope to the CFDI Parser. Target: one or more LinkedIn posts built with Python, SQL, FastAPI, pandas, Plotly, and Tableau Public. The DB grows daily as match results come in.

Project hub: `world-cup-2026/WC26 Main.md` in the brain vault (`C:\Users\gonti\brain`) — strategy, status, and cross-project links (learn-claude drills, linkedin-content posts). This file stays the truth for schema and conventions; the hub is the truth for status and roadmap. Never duplicate schema into the hub.

## Database Schema

**worldcup26.db** (rebuilt from `worldcup26_seed.sql` + `worldcup26_results.sql`)
- `teams`: team_id (TEXT PK — 3-letter FIFA code), fbref_team_id (TEXT UNIQUE — FBref squad-page hex; crosswalked for all 48 teams 2026-07-08), country (TEXT NOT NULL), confederation (TEXT NOT NULL), group_name (TEXT NOT NULL — 'A'–'L'), fifa_ranking (INTEGER), appearances (INTEGER — previous WC tournaments excl. WC26; 0 = first-timer), best_finish (TEXT — NULL for first-timers; values: 'Champion'/'Runner-up'/'Third place'/'Fourth place'/'Quarterfinals'/'Round of 16'/'Round of 32'/'Group stage'), coach (TEXT), host (INTEGER DEFAULT 0 — 1 = co-host MEX/USA/CAN), base_camp (TEXT — 'city, state, country'), market_value_m (REAL — Transfermarkt pre-tournament snapshot, EUR millions). All static.
- `players`: player_id (INTEGER PK AUTOINCREMENT), fbref_id (TEXT UNIQUE — FBref player id, stable join key), team_id (TEXT FK → teams.team_id), shirt_number (INTEGER), name (TEXT NOT NULL, indexed), position (TEXT NOT NULL — GK/DF/MF/FW; combos like FW-MF), goalkeeper_flag (INTEGER DEFAULT 0 — derived from `position LIKE '%GK%'`, seeded once so consumers don't each reimplement that check), birthday (TEXT — 'YYYY-MM-DD'), birthplace (TEXT — 'city, state, country'), league (TEXT), club (TEXT), matches_played (INTEGER), matches_started (INTEGER), minutes_played (INTEGER), goals (INTEGER), assists (INTEGER), yellow_cards (INTEGER), red_cards (INTEGER). All static. Career NT stats (matches_played → red_cards) sourced from FBref national team pages, excluding WC26 data. Nullable until populated.
- `matches`: match_id (INTEGER PK AUTOINCREMENT), fbref_match_id (TEXT UNIQUE — FBref match hex, pipeline join key), fifa_match_no (INTEGER UNIQUE), team_home (TEXT FK, NULL for unresolved knockout), team_away (TEXT FK, NULL for unresolved knockout), goals_home (INTEGER), goals_away (INTEGER), pk_home (INTEGER, NULL unless knockout + tied), pk_away (INTEGER, NULL unless knockout + tied), corners_home (INTEGER), corners_away (INTEGER), possession_home (REAL — % without sign), possession_away (REAL), stage (TEXT NOT NULL — 'group'/'r32'/'r16'/'qf'/'sf'/'third_place'/'final'), group_name (TEXT NOT NULL — 'A'–'L' for group stage, 'knock-out' for knockout), match_date (TEXT ISO 'YYYY-MM-DD'), match_time (TEXT 'HH:MM' local), stadium (TEXT), city (TEXT), attendance (INTEGER), referee (TEXT). Static fields: match_id, fifa_match_no, team_home/away (group fixed; knockout dynamic), stage, group_name, match_date, match_time, stadium, city. Dynamic fields (worldcup26_results.sql): goals_home/away, pk_home/away, corners_home/away, possession_home/away, attendance, referee.
- `player_stats`: stat_id (INTEGER PK AUTOINCREMENT), player_id (INTEGER FK → players.player_id), match_id (INTEGER FK → matches.match_id, indexed), minutes_played (Min), goals (Gls), assists (Ast), pk_made (G-PK), pk_att (PKatt), shots (Sh), shots_on_goal (SoT), yellow_cards (CrdY), red_cards (CrdR), fouls (Fls), fouls_drawn (Fld), offsides (Off), crosses (Crs), tackles_won (TklW), interceptions (Int), own_goals (OG), pk_won (PKwon), pk_conceded (PKcon) — all INTEGER DEFAULT 0. UNIQUE (player_id, match_id). Column order matches FBref Summary tab left-to-right. All dynamic — rows inserted via worldcup26_results.sql.
- `goalkeeper_stats`: stat_id (INTEGER PK AUTOINCREMENT), player_id (INTEGER FK → players.player_id), match_id (INTEGER FK → matches.match_id), minutes_played (INTEGER DEFAULT 0), shots_on_target_against (SoTA, INTEGER DEFAULT 0), goals_against (GA, INTEGER DEFAULT 0), saves (INTEGER DEFAULT 0). UNIQUE (player_id, match_id). Maps to FBref Goalkeeper Stats tab. save_pct is derived — never stored: CAST(saves AS REAL) / NULLIF(shots_on_target_against, 0). GK also appears in player_stats with outfield columns. All dynamic — rows inserted via worldcup26_results.sql.
- `metadata`: singleton table (one row, updated in place — no PK). schema_version (TEXT — semver, e.g. '1.0.0'), api_version (TEXT — NULL until wc26_api.py ships), last_sync (TEXT — ISO 8601 timestamp of the last wc26-daily-update run), last_matchday (TEXT — max match_date among played matches as of that run), records_imported (INTEGER — rows written by the **last run only**, a delta, never cumulative). Field ownership:

  | Field | Owner | Updated | Notes |
  |---|---|---|---|
  | `schema_version` | Human, seed-authored | Only on schema changes | Bump when `worldcup26_seed.sql`'s `CREATE TABLE`s change |
  | `api_version` | Human, seed-authored | Only on API changes | NULL until `wc26_api.py` ships |
  | `last_sync` | `wc26-daily-update` task | Every run | ISO 8601 timestamp of that run, not a bare date |
  | `last_matchday` | `wc26-daily-update` task | Every run | `MAX(match_date)` among played matches as of that run |
  | `records_imported` | `wc26-daily-update` task | Every run | **This-run delta** — rows written in that run, not a running total |

  `schema_version`/`api_version` are seeded in `worldcup26_seed.sql` with real values and only change when a human edits the seed. `last_sync`/`last_matchday` seed with a real snapshot as of authoring time (not a NULL placeholder — this table represents current status, not tournament history) and are UPDATEd via `worldcup26_results.sql` from then on. `records_imported` seeds NULL — no run had instrumented a per-run delta count before 2026-07-08, so NULL is the honest value; 0 or a backfilled cumulative number would misrepresent that gap.

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
- Daily result updates source: https://fbref.com/en/comps/1/2026/matches. Match results are fetched by the external `wc26-daily-update` scheduled skill (`C:\Users\gonti\Claude\Scheduled\wc26-daily-update\SKILL.md`, cron `0 0 * * *`) via the Firecrawl MCP connector (`firecrawl_scrape`, JSON extraction — no HTML file ever saved; migrated 2026-07-07). It: (1) UPDATEs matches with result + corners + possession + attendance + referee; (2) appends the same statements to `worldcup26_results.sql`. It explicitly does **not** load `player_stats`/`goalkeeper_stats` — see "FBref Pipeline (stats layer)" below, which is currently broken pending S7.
- **Dynamic field map** — `worldcup26_results.sql` contains exactly three statement types:
  - `UPDATE matches` — goals, pk, corners, possession, attendance, referee (post-match); team_home/team_away (knockout bracket, pre-match)
  - `INSERT INTO player_stats` — one row per player per match, all stat columns
  - `INSERT INTO goalkeeper_stats` — one row per GK per match, all stat columns
  - `teams` and `players` have no dynamic fields — never appear in worldcup26_results.sql
- **Score update rule**: match scores go into `worldcup26_results.sql` as `UPDATE` statements — never into `worldcup26_seed.sql`. Apply the same UPDATE to the live DB and append it to `worldcup26_results.sql`. The seed holds NULL goals as structural placeholders; rebuilding from seed intentionally wipes all scores.
- **Knockout team assignment rule**: once knockout teams are known, run `UPDATE matches SET team_home=?, team_away=? WHERE match_id=?` against the live DB and append to `worldcup26_results.sql`. Only update the seed when correcting structural data (wrong bracket position, wrong date).
- **Results layer rule**: `worldcup26_results.sql` accumulates **all** dynamic data — match score UPDATEs and player/GK stat INSERTs. Rebuild = `sqlite3 worldcup26.db < worldcup26_seed.sql && sqlite3 worldcup26.db < worldcup26_results.sql`. This file is the "final seed" for the LinkedIn-ready repo.
- **Canonical data source**: https://fbref.com/en/ — all player stats and match data come from FBref. Summary tab → `player_stats`. Goalkeeper Stats tab → `goalkeeper_stats`. Never INSERT or UPDATE from memory — always verify against FBref first.
- **FBref scraping — never `requests`/`curl`/`httpx`; the acquisition method now splits in two:** FBref blocks all bot/script access with Cloudflare, so direct `requests.get()` returns 403 either way. (1) Match-result fetching is handled by the external `wc26-daily-update` skill via the Firecrawl MCP connector (`firecrawl_scrape`) — migrated 2026-07-07, currently working. (2) `player_stats`/`goalkeeper_stats` acquisition (this repo's pipeline, below) still requires a Chrome-saved HTML file in `results/raw/` and is **currently broken — Chrome was uninstalled 2026-07-08**. Migrating this half to Firecrawl is S7 scope; do not attempt a `requests`-based workaround in the meantime.

## Data Integrity Invariants (never violate)

`players` table: every `team_id` has exactly 26 rows, and `shirt_number` across those 26 rows forms a complete, gapless, non-duplicated set of 1-26.
```sql
SELECT team_id, COUNT(*) AS n, COUNT(DISTINCT shirt_number) AS distinct_n
FROM players GROUP BY team_id
HAVING n != 26 OR distinct_n != 26
```
must return zero rows. FIFA's WC26 squad cap is 26 — more isn't extra data, it's wrong data (non-squad players contaminating the table). `COUNT(*) = 26` alone is necessary but not sufficient — verified 2026-07-08 that a team can hit 26 rows with a non-squad player occupying a slot that should belong to someone else (caught via `shirt_number`, not row count). Never trust a source to have already enforced this, including FBref's own squad pages — confirmed 2026-07-06 (Chunk Audit) that FBref returns 27-28 per squad in some cases, and Germany/Jordan squad-page fetches this session returned 44 and 56. Any script or fetch that adds player rows must be checked against this cap before trusting the count.

**Verification scale must match change scale — do not over-apply:**
- Schema changes, bulk backfills (multi-row batch operations across many players/matches/teams), and anything touching table structure → full rebuild-and-verify (scratch DB, compare all row counts, invariant checks) is mandatory.
- Single targeted fixes (one row, one or two columns — e.g. correcting one player's `fbref_id` or `position`) → verify with a direct scoped query confirming the specific change (`SELECT ... WHERE ...`), not a full pipeline rebuild. A full rebuild for a 1-row fix costs real time for no additional safety — the targeted query already proves correctness for that row, and nothing about a single-field UPDATE can silently corrupt unrelated rows the way a schema change or batch load can.

**Never run overlapping writes against the live DB:** `sqlite3` rebuild/apply commands against `worldcup26.db` must run sequentially, each fully waited-on before the next starts. Concurrent writes to the same SQLite file can partially truncate or corrupt tables mid-transaction — this happened 2026-07-08 (`matches` 96→65, `player_stats` 2263→816, `goalkeeper_stats` 149→2) from multiple unmonitored background rebuild processes firing against the live DB at once. The source `.sql` files were unaffected; only the derived `.db` binary was. Recovery is always a single clean sequential rebuild from seed+results, never a race to fix it faster with parallel attempts.

## FBref Pipeline (stats layer)

The production pipeline that fills `player_stats` / `goalkeeper_stats`. Four layers — acquire is the only one that touches the network; everything downstream is local and idempotent.

```
1. ACQUIRE   ⚠ BROKEN (Chrome uninstalled 2026-07-08) — was: Claude in Chrome → results/raw/{hex}.html
             Migrating this step to Firecrawl is S7 scope — not yet done.
             fbref_urls.py   — URL/hex registry scraped from the FBref schedule page
             fbref_move.py   — moves Chrome-downloaded HTMLs (Downloads/) → results/raw/. Dead until S7 — no Chrome to download from.
             fbref_fetch.py  — DEAD REFERENCE: requests.get → 403 (Cloudflare). Kept to document why.
2. PARSE     fbref_parse.py {hex} → results/{hex}_players.csv + {hex}_keepers.csv
             Finds ALL stats_*_summary + keeper_stats_* tables (both teams, regex on table id).
             Extracts fbref_id from data-append-csv BEFORE read_html; stamps team_id + match hex on every row.
3. LOAD      fbref_load.py {hex} → INSERT OR REPLACE into player_stats + goalkeeper_stats (live DB)
             fbref_batch.py — parse+load every match with HTML on disk but no stats rows yet (resumable)
4. MIRROR    generate_inserts.py — exports all stat rows as INSERT OR IGNORE, appends to worldcup26_results.sql
             ⚠ run ONCE per batch — re-running duplicates lines in the .sql (harmless in DB, ugly in file)
```

**Identity resolution — never join on names.** Players resolve via `players.fbref_id` (from the `data-append-csv` attribute); matches resolve via `matches.fbref_match_id` (the URL hex). Name joins broke on accent drift (`Rüdiger` vs `Ruediger`) — that's why both crosswalk columns exist. `fbref_map_matches.py` populates `matches.fbref_match_id` from URL slugs (SLUG_TO_CODE map for non-obvious country codes). A missing crosswalk row = load skipped + logged, never a wrong id.

**Idempotency:** loader is `INSERT OR REPLACE` — FBref revises stats post-match, so a re-pull overwrites (stat_id churn is harmless, nothing references it). The results.sql mirror is `INSERT OR IGNORE`.

**Standing verification (after every batch):** rebuild `seed + results` into a scratch DB and compare row counts (`matches` played, `player_stats`, `goalkeeper_stats`) against the live DB. The two known lockstep failure modes are stats loaded without score UPDATEs (Jun 27 batch) and results.sql UPDATEs never applied to the live DB (R32 batch) — the rebuild test catches both directions.

**Daily flow, current state (two separate tasks, don't conflate them):** Match results are fully handled by the external `wc26-daily-update` skill (Firecrawl-based, working) — verify on FBref → `UPDATE matches` (score, corners, possession, attendance, referee) → append to results.sql. Done there; not this repo's concern. `player_stats`/`goalkeeper_stats` are **blocked** — the acquisition step (Chrome → `results/raw/{hex}.html`) is broken since Chrome was uninstalled 2026-07-08. Once acquisition is fixed (S7), the rest of the chain is unchanged: `fbref_batch.py` → `generate_inserts.py` → rebuild test → `UPDATE metadata SET last_sync=..., last_matchday=..., records_imported=...` in live DB + append to results.sql.

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

**Cowork sessions (build mode) — staging rule:**
When German is in Cowork and says "you write," Claude writes. Code Claude writes in Cowork counts as **🌱 Exposure** in the SpacedRep tracker — he observed it, not produced it. **Reproduction still requires a cold write in a Claude Code session.** Rule: "you write → Exposure. you write again → maybe Comprehension." Never award Reproduction from a Cowork-built script.

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
- **One trigger, not five steps.** Use `/wrap <prefix>` to collapse diff → stage → commit → push into a single command (live in Claude Code).
- **The Sunday Reflection checks this repo's `git status` + last-commit age** — the backstop that catches a multi-day uncommitted backlog before it grows. (See `Learning_OS.md` §11 in the brain vault — `C:\Users\gonti\brain`, the canonical home of all AI md context since 2026-07-02.)

## File layout

```
world-cup-2026/
├── worldcup26.db            — SQLite database (live, grows daily, tracked in git)
├── worldcup26_seed.sql      — pure structural baseline (schema + reference data + NULL score placeholders)
├── worldcup26_results.sql   — dynamic data accumulator (match score UPDATEs + player/GK stat INSERTs)
├── fbref_urls.py            — FBref match URL/hex registry
├── fbref_fetch.py           — dead reference (requests → 403; acquire = Chrome, now broken — uninstalled 2026-07-08, S7 migrates to Firecrawl)
├── fbref_move.py            — Downloads/ → results/raw/. Dead until S7 — no Chrome to download from.
├── fbref_parse.py           — raw HTML → per-match players/keepers CSVs
├── fbref_load.py            — CSVs → player_stats + goalkeeper_stats
├── fbref_batch.py           — parse+load all fetched-but-unloaded matches
├── fbref_map_matches.py     — populates matches.fbref_match_id from URL slugs
├── generate_inserts.py      — mirrors stat rows into worldcup26_results.sql
├── wc26_standings.py        — group standings from played matches
├── wc26_viz.py              — Plotly viz (money vs goals scatter)
├── CLAUDE.md                — this file
├── results/                 — per-match CSVs; results/raw/ = HTML acquired via Chrome (broken since 2026-07-08 — S7 migrates to Firecrawl)
├── .claude/
│   ├── commands/            — slash commands (S4)
│   └── skills/              — domain knowledge files (always-on context)
└── [session files]          — wc26_report.py, wc26_api.py (planned)
```