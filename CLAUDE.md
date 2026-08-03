# CLAUDE.md — world-cup-2026

Guidance for Claude Code working in this repository.

## Operating model

- **Claude Code lives in this repo** — executes, commits, tests, ships.
- **Claude Cowork lives in brain** (`C:\Users\<you>\brain`) — plans, reviews, orchestrates.
- **Germán steers the wheel.**
- **Claude Code never edits brain vault files — ever.** Brain is read-only context; all vault edits come from Cowork or Germán.

| | repo files | vault files | repo git | vault git |
|---|---|---|---|---|
| Claude Code | read/write | read only | commit/push | never |
| Claude Cowork | read only | read/write | read only | read only |
| Germán | all | all | all | sole committer (Obsidian Git plugin) |

**Handoff:** Cowork drafts repo files → session outputs → Germán places and commits from Code. Repo-writing automations run as Claude Code (`claude -p`), never as Cowork.

⚠️ **Since 2026-07-28 this repo is WSL2-native (ext4) and is not mountable as a Windows folder.** Cowork's "read only" row is therefore theoretical here — it must be pointed at `\\wsl$\Ubuntu\...` to read anything. In practice repo work is Claude Code's, and Cowork contributes drafts.

## Project

World Cup 2026 (WC26) — a live SQLite database of the FIFA World Cup 2026 (Jun 11 – Jul 19, 2026), built and grown session by session. **Phase 4 build** — the active public showcase and data-engineering pipeline for technical content. Target: LinkedIn posts built with Python, SQL, FastAPI, pandas, Plotly, and Tableau Public.

**State (2026-07-28).** Schema at v1.1.0 (11 all-NULL career-NT columns dropped from `players`; S6 froze v1.0.0 2026-07-08). **Tournament complete — Spain champions; 104/104 matches played and loaded with stats.** Results layer: `wc26_update.py` owns acquire→verify, `results.sql` is generated, ACQUIRE runs on the Firecrawl API (Cloudflare cleared via the direct API path; the MCP path 403s). The stale-`player_id` attribution bug (from the S6 26-cap `players` renumber) was fixed by a full stats reload; VERIFY now also enforces team-membership + goals-reconcile invariants. Three charts ship from `wc26_viz.py`. All S7b work (backfill + schema v1.1.0) is merged to `main` via PR #2.

**Phase note:** wc26 graduated Phase 3 (Learning) → Phase 4 (Building) on 2026-07-27. Claude Code builds here now — see [Working mode](#working-mode) for what survived from the learning phase.

Project hub: `building/world-cup-2026/WC26 Main.md` in brain — status, roadmap, cross-project links. **This file is the truth for schema and conventions; the hub is the truth for status and roadmap. Never duplicate one into the other.**

## Database schema

**worldcup26.db** — rebuilt from `worldcup26_seed.sql` + `worldcup26_results.sql`.

- `teams`: team_id (TEXT PK — 3-letter FIFA code), fbref_team_id (TEXT UNIQUE — FBref squad-page hex), country (TEXT NOT NULL), confederation (TEXT NOT NULL), group_name (TEXT NOT NULL — 'A'–'L'), fifa_ranking (INTEGER), appearances (INTEGER — previous WCs; 0 = first-timer), best_finish (TEXT — NULL for first-timers; 'Champion'/'Runner-up'/'Third place'/'Fourth place'/'Quarterfinals'/'Round of 16'/'Round of 32'/'Group stage'), coach (TEXT), host (INTEGER DEFAULT 0 — 1 = MEX/USA/CAN), base_camp (TEXT — 'city, state, country'), market_value_m (REAL — Transfermarkt pre-tournament snapshot, EUR millions). All static.
- `players`: player_id (INTEGER PK AUTOINCREMENT), fbref_id (TEXT UNIQUE — FBref player id, stable join key), team_id (TEXT FK → teams), shirt_number (INTEGER), name (TEXT NOT NULL, indexed), position (TEXT NOT NULL — GK/DF/MF/FW; combos like FW-MF), goalkeeper_flag (INTEGER DEFAULT 0 — derived from `position LIKE '%GK%'`, seeded once), birthday (TEXT 'YYYY-MM-DD'), birthplace (TEXT — 'city, state, country'), league (TEXT), club (TEXT). All static.
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
Run script:  python3 wc26_viz.py
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

- `goals_home`/`goals_away` are NULL until played — standings and stats queries filter `WHERE goals_home IS NOT NULL`. (Tournament is complete, so this now excludes nothing — keep it anyway; the seed still carries placeholders and a rebuild replays them.)
- `matches` stores `team_id` refs, never country names — JOIN `teams` for display.

**Source of truth:**

- Canonical source: <https://fbref.com> — Summary tab → `player_stats`, Goalkeeper Stats tab → `goalkeeper_stats`, schedule page → results. **Never INSERT or UPDATE from memory** — verify on FBref first, including whether a match has been played.

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

⚠️ **Known accepted exception — do not "fix" it blind.** The KSA roster has a deferred gap: **match 15 / Al-Amri (`fd0affe3`) is missing from `players`**, allowlisted as `KNOWN_GOAL_GAPS={15}` in `wc26_verify.py`. **`wc26_verify.py` is the authority on which gaps are accepted** — if the cap query returns a row, check the allowlist before treating it as a defect. Any *new* violation is real.

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
               Raw HTML only — no LLM extraction. Pass match URLs directly; acquire derives the hex.
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
- **Identity resolution — never join on names.** Players resolve via `players.fbref_id`; matches via `matches.fbref_match_id` (URL hex, set directly on the live DB when a match is resolved). Name joins broke on accent drift. A missing crosswalk row = load skipped + logged, never a wrong id.
- **Idempotency:** loader is `INSERT OR REPLACE` (FBref revises stats post-match; stat_id churn is harmless — nothing references it, and VERIFY excludes it from digests). The results.sql stat mirror is `INSERT OR IGNORE`.
- **Match-level atomicity:** a page yielding fewer than two summary/keeper tables is a **match failure** — skip the whole match, log it. Never half-load; one team's stats loaded alone reads as "the other team didn't play".
- **VERIFY's two checks are different in kind:** live vs scratch rebuild must be **exact** (row digests, not just counts — counts miss value drift). The second check is the count floor — see below.
- **`requests` against `api.firecrawl.dev` is allowed** and does not violate the rule above — that rule is about hitting fbref.com directly. Firecrawl performs the FBref fetch; `fbref_acquire.py` only talks to Firecrawl's API. If a fetch 403s, the sanctioned fallback is a manual browser-save into `results/raw/` — never a `requests` workaround against fbref.com.

**Count floor — should be fixed, is still monotonic.** The 2026-07-13 baseline (2,263 / 149 / 100 played) was a *monotonic floor* while the tournament ran: counts could only grow. **The tournament ended 2026-07-19 at 104/104**, so the floor should now be a **fixed equality target** — a count that moves in either direction is a defect, not progress.

⚠️ **Not applied — confirmed 2026-07-28.** `wc26_verify.py` still carries `FLOOR = {"player_stats": 2263, "goalkeeper_stats": 149, "matches_played": 100}` and `check_floor()` still only flags `count < floor`. The live final counts are **3,283 / 215 / 104**, so the floor sits ~1,000 rows stale: a regression that silently dropped a thousand `player_stats` rows would still pass VERIFY. Converting it to equality against the final counts is open work.

## Prohibited (never do)

- No f-strings or string concatenation in SQL queries
- No `import *`
- No `print()` as the only error signal in pipeline code — use `logging` (formatted tables for human-facing reports are fine)
- No `SUM() OVER (PARTITION BY)` inside aggregation CTEs — duplicate rows in SQLite
- No `RANK()` in human-facing output — use `DENSE_RANK()`
- No editing `worldcup26.db` schema directly — change the seed and rebuild
- No hallucinated match results — verify on FBref before any UPDATE or INSERT. If you wouldn't trust the number, verify before touching the query.
- No hand-editing `worldcup26_results.sql` — it is generated

## Working mode

wc26 graduated out of the learning phase on 2026-07-27 (Phase 3 → Phase 4). **Claude Code builds, tests, and ships here** under the conventions above — the former "spec it, never write it" protocol no longer applies.

Two rules carried over, because they are about how Germán's skill is *recorded*, not about who may write code:

- **Cowork staging rule.** Code Claude writes in a Cowork session counts as 🌱 Exposure in the Learning Tracker — he observed it, not produced it. Reproduction requires a cold write in a Claude Code session. Never award Reproduction from a Cowork-built script.
- **Never mark a drill done.** If a task is framed as a drill, Germán writes it cold and updates the Learning Tracker himself. Claude reviews; Claude does not self-certify his progress.

When reviewing his code, stay step by step, line by line — no full-solution dumps. That habit outlived the phase because it is what makes review useful.

## Skills

Domain knowledge as folder-style Agent Skills — `.claude/skills/<name>/SKILL.md` with `name`/`description` frontmatter, loaded on demand when the task matches:

- `python-hardening` — Python/SQLite hardening conventions
- `worldcup-sql-report` — SQL reporting patterns for this schema

⚠️ **Migration pending.** These currently live as flat files (`python-hardening.md`, `worldcup-sql-report.md`) loaded via always-on `@`-refs, which costs their full context on every session regardless of task. The vault converted to on-demand folder skills on 2026-07-09; this repo has not. Convert to `skills/<name>/SKILL.md` with frontmatter and drop the `@`-refs.

## Git workflow

Full standard: brain `Repos.md` → **Git standard** (adopted 2026-07-29). Summary that binds here:

- **Policy:** public GitHub remote; `worldcup26.db` IS tracked (live data); push at session end — registered in brain `Repos.md`.
- `git diff` first, always. Stage specific files — never `git add .`. Never force-push.
- **Commit format:** `<type>(<scope>): <subject>` — closed set of seven types (`feat` · `fix` · `data` · `schema` · `docs` · `chore` · `wip`). Scope carries the sprint where sprints exist (`data(s9): ...`); omit it otherwise. The retired `s<N>:` prefix is no longer used. If a commit doesn't fit one type, it's two commits.
- **`data`, `schema` and `fix` require a body carrying the numbers** — row counts, table names, what changed. Earned 2026-07-28 when the ledger dropped `aa2c1fb`, the commit that performed the knockout backfill, while keeping three hygiene commits. The commit that changes the data is the one the ledger exists to remember.
- **Branches — trunk-based.** Commit to `main` directly (solo repo; a branch buys nothing and costs the topology). Branch only when the PR is wanted as public record or a schema-level revert point matters. **A merged branch dies in the same breath as the merge** — delete-on-merge is enabled in GitHub settings; `/wrap` runs `git fetch --prune`.
- **`.pre-commit-config.yaml` is armed** (`pre-commit install` run) — whitespace/EOF/YAML/merge-conflict/large-file checks (with a `*.db` exclusion for the tracked `worldcup26.db`) + `ruff-check --fix` then `ruff-format`. `--no-verify` bypasses it; that's a deliberate act, not a shortcut.
- **A session is not done until git is clean.** `wip:` commits are encouraged mid-flow — a messy paper trail beats no paper trail. `/wrap <prefix>` collapses diff → stage → commit → push, runs `git fetch --prune`, and prints `git branch -vv`.
- `/wrap` ends by **printing the session's drift summary plus `git branch -vv`** — Germán or a Cowork session logs it in brain `Repos.md` (Code never writes to the vault). **That handoff is the only backstop.** There is no automated safety net: the `wc26-eod-git-check` scheduled task and the Sunday Reflection are both disabled as of 2026-07-28. The branch print exists because `/wrap` is commit-scoped and missed graph-scoped drift before: wc26 ran clean `/wrap`s through S7 and S8 and still ended with three branches, HEAD unmerged, and local `main` 8 behind — see brain `Repos.md` for the 2026-07-29 branch-tidy resolution. If `/wrap` doesn't print the summary and someone doesn't log it, the drift is invisible.

## File layout

```
world-cup-2026/                 — ~/repos/world-cup-2026 (WSL2 ext4 since 2026-07-28)
├── worldcup26.db            — SQLite database (live, tracked in git)
├── worldcup26_seed.sql      — pure structural baseline (schema + reference data + NULL placeholders)
├── worldcup26_results.sql   — GENERATED artifact (never hand-edit) — regenerated from live DB
├── wc26_update.py           — ⭐ the UPD node: acquire→parse→load→metadata→regenerate→verify
├── fbref_acquire.py         — ACQUIRE: Firecrawl API → results/raw/{hex}.html
├── fbref_parse.py           — PARSE: raw HTML → per-match players/keepers CSVs
├── fbref_load.py            — LOAD: CSVs → player_stats + goalkeeper_stats
├── wc26_regenerate.py       — REGENERATE: live DB → worldcup26_results.sql (pure serializer)
├── wc26_verify.py           — VERIFY: scratch rebuild from seed+results, diffed against live
├── wc26_viz.py              — Plotly viz (money-vs-goals, finishing-efficiency, LinkedIn dark charts)
├── CLAUDE.md                — this file
├── README.md                — repo front door / map
├── .env                     — FIRECRAWL_API_KEY (gitignored — public repo)
├── archive/                 — superseded scripts, kept to document what broke and why
│   ├── generate_inserts.py  — dead (append-only, non-idempotent) → wc26_regenerate.py
│   ├── fbref_batch.py       — dead (stopped at LOAD) → wc26_update.py
│   ├── wc26_loader.py       — dead (early CSV loader) → fbref_load.py + wc26_update.py
│   ├── fbref_urls.py        — dead (static URL registry, never imported) → URLs passed to /update-results
│   ├── fbref_map_matches.py — dead (stale 94-match slug map) → direct fbref_match_id UPDATEs
│   └── wc26_standings.py    — dead (standalone) → group-standings skill
├── drills/                  — drill working files
├── results/                 — per-match CSVs; results/raw/ = acquired HTML (gitignored)
├── .claude/
│   ├── commands/            — slash commands (/update-results, /wrap live here)
│   └── skills/              — domain knowledge (see Skills — conversion pending)
└── [session files]          — wc26_report.py, wc26_api.py (planned)
```

⚠️ **Verify this tree against `ls -a` before trusting it.** `fbref_fetch.py` was listed here as a dead reference but is not present in the working tree; `drills/` was present but unlisted. Both corrected 2026-07-28 from a directory listing, not from a live check.
