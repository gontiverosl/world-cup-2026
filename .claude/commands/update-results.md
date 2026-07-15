---
description: Acquire + load FBref match stats, regenerate worldcup26_results.sql, verify the rebuild
argument-hint: <fbref-match-url> [<fbref-match-url> ...]  — or no args to regenerate + verify only
---

Run the results pipeline. Input: **$ARGUMENTS** — zero or more FBref match URLs (space-separated); a bare match hex also works.

```
ACQUIRE → PARSE → LOAD → metadata → REGENERATE → VERIFY
```

```bash
python3 wc26_update.py $ARGUMENTS
```

`wc26_update.py` owns the whole path — don't run the nodes by hand unless you're debugging one.

**What it does**
- **ACQUIRE** — `fbref_acquire.py` fetches each page via the Firecrawl API into `results/raw/{hex}.html`. Skips anything already on disk. Needs `FIRECRAWL_API_KEY` (read from `.env`, which is gitignored — this is a public repo).
- **PARSE + LOAD** — incremental: only matches with HTML on disk and no `player_stats` rows. A page yielding fewer than two summary/keeper tables is a **match failure** — skipped whole, logged, never half-loaded.
- **REGENERATE** — rewrites `worldcup26_results.sql` wholesale from live DB state.
- **VERIFY** — rebuilds a scratch DB from seed + results and asserts it equals live exactly.

**Rules that matter here**
- `worldcup26_results.sql` is a **generated artifact**. Never hand-edit it — the next run overwrites it. To change data: change the live DB, then re-run this command.
- Zero args is a valid, useful run: it regenerates + verifies from current live state. Do this after any manual live-DB change (e.g. a knockout bracket resolution via `/add-result`), otherwise the file drifts from the DB.
- **Never INSERT/UPDATE from memory** — verify on FBref first, including whether a match has actually been played.

**Reading the output**
- `VERIFY PASSED` — seed + results rebuilds live exactly. The only acceptable end state.
- `MISMATCH` on any table — loud failure, exit 1. Investigate before trusting the file; do not re-run hoping it clears. It means live and results.sql disagree.
- `BELOW FLOOR` — a count dropped under the 2026-07-13 baseline (2,263 / 149 / 100 played). Data loss; stop and investigate.
- Per-match `SKIPPED` / `FAILED` lines are in `worldcup26.log` with the reason.

If a fetch 403s, don't reach for `requests` against fbref.com — that rule stands. Manual browser-save into `results/raw/` is the sanctioned fallback; everything from PARSE on is unchanged.
