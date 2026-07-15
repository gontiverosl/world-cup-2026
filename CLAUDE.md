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

**State after S7a (2026-07-14):** schema frozen (v1.0.0, S6 closed 2026-07-08). Results layer rebuilt — `wc26_update.py` owns acquire→verify, `results.sql` is now generated, ACQUIRE runs on the Firecrawl API (Cloudflare cleared via the direct API path; the MCP path 403s). S7b = backfill the 27 played matches still missing stats, then first chart + LinkedIn post.

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
  | `last_sync` | `wc26_update.py` | Every run | ISO 8601 timestamp, not a bare date |
  | `last_matchday` | `wc26_update.py` | Every run | `MAX(match_date)` among played matches |
  | `records_imported` | `wc26_update.py` | Every run | **Snapshot**: total `player_stats` + `goalkeeper_stats` rows now present |

  `records_imported` was redefined in S7a (2026-07-14): it used to be a this-run delta, which stopped meaning anything once every run regenerates the whole file. It is now a snapshot total. The three task-owned fields are written to the **live DB** by `wc26_update.py`; `wc26_regenerate.py` only serializes them into results.sql. `schema_version`/`api_version` are seed-authored and never restated in results.sql — a results file must not be able to override a schema bump.

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
- `worldcup26_results.sql` = **generated artifact** carrying all dynamic data; exactly four statement types: `UPDATE matches` (goals/pk/corners/possession/attendance/referee post-match; team_home/away for knockout brackets pre-match), `INSERT OR IGNORE INTO player_stats`, `INSERT OR IGNORE INTO goalkeeper_stats`, and one `UPDATE metadata`. `teams` and `players` never appear here.
- **The live DB is the source of truth; results.sql is derived from it** (S7a, 2026-07-14 — it is no longer hand-appended). Every dynamic change: apply to the live DB, then run `/update-results` to regenerate + verify. Rebuild = seed then results; rebuilding intentionally wipes and replays all dynamic data.

**Query rules:**
- `goals_home`/`goals_away` are NULL until played — standings and stats queries filter `WHERE goals_home IS NOT NULL`.
- `matches` stores `team_id` refs, never country names — JOIN `teams` for display.

**Source of truth:**
- Canonical source: https://fbref.com — Summary tab → `player_stats`, Goalkeeper Stats tab → `goalkeeper_stats`, schedule page → results. **Never INSERT or UPDATE from memory** — verify on FBref first, including whether a match has been played.

## Acquisition (FBref × Cloudflare)

**Never `requests`/`curl`/`httpx` against fbref.com** — FBref 403s all direct script access. Fetch via **Firecrawl**; `requests` against `api.firecrawl.dev` is fine (see the pipeline section).

- **Which Firecrawl path works (proven 2026-07-14):** the **direct API** (`fbref_acquire.py`) fetches match pages cleanly. The **Firecrawl MCP** 403s on the same pages ("Just a moment...", stealth + enhanced proxies both blocked, `waitFor` silently ignored). Scripts can't call MCP anyway — the API path is the production method for stats.
- **Comment-seam myth, settled:** FBref match pages serve `stats_*_summary` / `keeper_stats_*` **uncommented in the DOM**. Firecrawl's `formats:["html"]` output parses byte-identically to the old Chrome saves (A/B'd on `c4104726`: 30 players / 2 keepers, all 18 stat columns equal). No un-commenting seam needed for match pages. Set `onlyMainContent:false` — main-content extraction would strip the tables.
- **Player/GK stats — working (S7a):** `/update-results <url>`. Raw HTML + regex only; **never Firecrawl LLM extraction** (hallucination risk).
- **Match results — `wc26-daily-update` retired 2026-07-15.** Match results now flow exclusively through `/update-results`.

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

Fills `player_stats`/`goalkeeper_stats` and owns `worldcup26_results.sql`. **`wc26_update.py` orchestrates the whole path — run `/update-results`, not the nodes by hand** (nodes are individually runnable for debugging only). ACQUIRE is the only node that touches the network; everything downstream is local and idempotent.

```
   /update-results <url> ...  →  wc26_update.py
       ACQUIRE → PARSE → LOAD → metadata → REGENERATE → VERIFY
       └─ incremental (new matches only) ─┘  └─ always full, from live DB ─┘

1. ACQUIRE     fbref_acquire.py <url|hex> ... → results/raw/{hex}.html
               Firecrawl API (requests → api.firecrawl.dev; key from gitignored .env).
               formats:["html"], onlyMainContent:false, proxy:"auto", waitFor.
               Raw HTML only — no LLM extraction. fbref_urls.py = URL/hex registry.
2. PARSE       fbref_parse.py {hex} → results/{hex}_players.csv + {hex}_keepers.csv
               Finds ALL stats_*_summary + keeper_stats_* tables (both teams, regex on table id).
               Extracts fbref_id from data-append-csv BEFORE read_html; stamps team_id + hex.
3. LOAD        fbref_load.py {hex} → INSERT OR REPLACE into player_stats + goalkeeper_stats
4. REGENERATE  wc26_regenerate.py → rewrites worldcup26_results.sql WHOLESALE from live DB
5. VERIFY      wc26_verify.py → scratch rebuild from seed+results, diffed against live
```

- **`worldcup26_results.sql` is a GENERATED ARTIFACT — never hand-edit it.** The next run overwrites it. To change data: change the live DB, then regenerate. Any manual live-DB change (e.g. a knockout bracket resolution) must be followed by a bare `/update-results` or the file drifts from the DB.
- **REGENERATE is a pure serializer** — reads live DB, writes the file, computes nothing. No bracket logic inside it. Its selection rule is **not** "played matches": it is *any `matches` row whose live state differs from the seed placeholder* — score present **OR** knockout teams resolved. A played-only rule would silently drop resolved-but-unplayed brackets, which rebuild as NULL teams with no error.
- **Deterministic ordering is the contract:** `matches` by `match_id`; `player_stats`/`goalkeeper_stats` by `(match_id, player_id)`. Regenerating twice from unchanged live state is byte-identical. That's why no clock lives inside the serializer — `wc26_update.py` writes `last_sync` to the live DB, REGENERATE only serializes it.
- **Identity resolution — never join on names.** Players resolve via `players.fbref_id`; matches via `matches.fbref_match_id` (URL hex; `fbref_map_matches.py` populates it, SLUG_TO_CODE for non-obvious codes). Name joins broke on accent drift. A missing crosswalk row = load skipped + logged, never a wrong id.
- **Idempotency:** loader is `INSERT OR REPLACE` (FBref revises stats post-match; stat_id churn is harmless — nothing references it, and VERIFY excludes it from digests). The results.sql stat mirror is `INSERT OR IGNORE`.
- **Match-level atomicity:** a page yielding fewer than two summary/keeper tables is a **match failure** — skip the whole match, log it. Never half-load; one team's stats loaded alone reads as "the other team didn't play".
- **VERIFY's two checks are different in kind:** live vs scratch rebuild must be **exact** (row digests, not just counts — counts miss value drift). The 2026-07-13 baseline (2,263 / 149 / 100 played) is a **monotonic floor** — counts never decrease — never an equality target; it goes stale the moment a match loads. After the final (Jul 19) the floor becomes the fixed expected final counts.
- **`requests` against `api.firecrawl.dev` is allowed** and does not violate the rule below — that rule is about hitting fbref.com directly. Firecrawl performs the FBref fetch; `fbref_acquire.py` only talks to Firecrawl's API. If a fetch 403s, the sanctioned fallback is a manual browser-save into `results/raw/` — never a `requests` workaround against fbref.com.

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
├── worldcup26_results.sql   — GENERATED artifact (never hand-edit) — regenerated from live DB
├── wc26_update.py           — ⭐ the UPD node: acquire→parse→load→metadata→regenerate→verify
├── fbref_acquire.py         — ACQUIRE: Firecrawl API → results/raw/{hex}.html
├── fbref_parse.py           — PARSE: raw HTML → per-match players/keepers CSVs
├── fbref_load.py            — LOAD: CSVs → player_stats + goalkeeper_stats
├── wc26_regenerate.py       — REGENERATE: live DB → worldcup26_results.sql (pure serializer)
├── wc26_verify.py           — VERIFY: scratch rebuild from seed+results, diffed against live
├── fbref_urls.py            — FBref match URL/hex registry
├── fbref_map_matches.py     — populates matches.fbref_match_id from URL slugs
├── fbref_fetch.py           — dead reference (requests → fbref.com → 403; kept to document why)
├── wc26_standings.py        — group standings from played matches
├── wc26_viz.py              — Plotly viz (money vs goals scatter)
├── CLAUDE.md                — this file
├── .env                     — FIRECRAWL_API_KEY (gitignored — public repo)
├── archive/                 — superseded scripts, kept to document what broke and why
│   ├── generate_inserts.py  — dead (append-only, non-idempotent) → wc26_regenerate.py
│   └── fbref_batch.py       — dead (stopped at LOAD) → wc26_update.py
├── results/                 — per-match CSVs; results/raw/ = acquired HTML (gitignored)
├── .claude/
│   ├── commands/            — slash commands (/update-results, /wrap live here)
│   └── skills/              — domain knowledge files
└── [session files]          — wc26_report.py, wc26_api.py (planned)
```
