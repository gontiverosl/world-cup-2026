# WC26 SQL Report Patterns

Domain knowledge for worldcup26.db queries. Read alongside CLAUDE.md.

---

## Schema Quick Reference

```
teams        — team_id (PK, 3-letter FIFA code), country, confederation,
               group_name ('A'–'L'), fifa_ranking, appearances (prior WC
               tournaments excl. WC26; 0 = first-timer), best_finish
               (NULL for first-timers), coach, host (1 = co-host
               MEX/USA/CAN), base_camp, market_value_m

players      — player_id (PK AUTOINCREMENT), team_id (FK), shirt_number,
               name, position (GK/DF/MF/FW, combos like FW-MF), footed
               (Left/Right), birthday ('YYYY-MM-DD'), birthplace, league,
               club, matches_played, matches_started, minutes_played,
               goals, assists, yellow_cards, red_cards
               (career NT stats, from FBref NT pages, excl. WC26 — nullable
               until backfilled)

matches      — match_id (PK AUTOINCREMENT), fifa_match_no (UNIQUE),
               team_home (FK, NULL if knockout team not yet known),
               team_away (FK, NULL if knockout team not yet known),
               goals_home (NULL = not yet played), goals_away,
               pk_home / pk_away (NULL unless knockout + tied),
               corners_home / corners_away, possession_home / possession_away
               (REAL %, no sign), stage ('group'/'r32'/'r16'/'qf'/'sf'/
               'third_place'/'final'), group_name ('A'–'L' for group stage,
               'knock-out' for knockout — NEVER NULL), match_date
               ('YYYY-MM-DD'), match_time ('HH:MM' local), stadium, city,
               attendance, referee

player_stats — stat_id (PK AUTOINCREMENT), player_id (FK), match_id (FK),
               minutes_played, goals, assists, pk_made, pk_att, shots,
               shots_on_goal, yellow_cards, red_cards, fouls, fouls_drawn,
               offsides, crosses, tackles_won, interceptions, own_goals,
               pk_won, pk_conceded — all INTEGER DEFAULT 0
               UNIQUE (player_id, match_id). Column order matches FBref
               Summary tab left-to-right.

goalkeeper_stats — stat_id (PK AUTOINCREMENT), player_id (FK), match_id (FK),
               minutes_played, shots_on_target_against, goals_against, saves
               — all INTEGER DEFAULT 0. UNIQUE (player_id, match_id).
               save_pct is DERIVED, never stored:
               CAST(saves AS REAL) / NULLIF(shots_on_target_against, 0)
               A GK also appears in player_stats with outfield columns —
               that's intended, don't dedupe across the two tables.
```

---

## The NULL Rules

**goals_home / goals_away IS NULL = match not yet played.**
Every standings and stats query must filter: `WHERE goals_home IS NOT NULL`

**team_home / team_away IS NULL = knockout teams not yet determined.**
Knockout bracket slots are pre-inserted with NULL teams. Assign teams once qualifying results are in.

**group_name is NEVER NULL** — it's `'A'`–`'L'` for group-stage matches and the literal string `'knock-out'` for every knockout match. To isolate group-stage matches, filter `WHERE group_name != 'knock-out'`, not `IS NOT NULL` (that used to be right when knockout rows had NULL group_name — schema changed, this filter did not, and it now silently passes everything).

**matches stores team_id codes, never country names.**
Always JOIN to teams for display: `JOIN teams t ON m.team_home = t.team_id`

---

## Seed / Results / Live DB Rules

| What | Where |
|------|-------|
| Schema changes (new tables, columns) | `worldcup26_seed.sql` FIRST, then rebuild |
| Match scores, pk, corners, possession, attendance, referee | `worldcup26_results.sql` as `UPDATE matches` — never in seed |
| Knockout team assignments | `worldcup26_results.sql` as `UPDATE matches` — never in seed |
| `player_stats` / `goalkeeper_stats` rows | `worldcup26_results.sql` as `INSERT` — table definitions only in seed, rows only in results |
| Squad/team static data | `worldcup26_seed.sql` |

**Rebuild command (two steps, always both):**
`sqlite3 worldcup26.db < worldcup26_seed.sql && sqlite3 worldcup26.db < worldcup26_results.sql`

Running the seed alone wipes scores/stats back to NULL placeholders — that's expected mid-command, not a finished state. The results.sql step immediately after is what restores every score, stat row, and knockout assignment. There is no daily-update task that "restores" data after a bare seed rebuild; always run both files as one operation.

---

## Standard Query Patterns

### Golden Boot / Leaderboard (DENSE_RANK)

```sql
WITH ranked AS (
    SELECT
        p.name,
        t.country,
        SUM(ps.goals) AS tournament_goals,
        DENSE_RANK() OVER (ORDER BY SUM(ps.goals) DESC) AS rank
    FROM player_stats ps
    JOIN players p ON ps.player_id = p.player_id
    JOIN teams t ON p.team_id = t.team_id
    GROUP BY ps.player_id
)
SELECT * FROM ranked WHERE rank <= 10;
```

- Use DENSE_RANK(), never RANK() — no gaps after ties
- Window alias not usable in WHERE — always wrap in CTE and filter in outer query
- `player_stats` is the real tournament-goals source — no proxy needed once it's populated (see Known Issues below for the one thing to confirm before deleting the old proxy note)

### Group Standings (Multi-CTE)

```sql
WITH results AS (
    SELECT team_home AS team_id,
           SUM(CASE WHEN goals_home > goals_away THEN 3
                    WHEN goals_home = goals_away THEN 1 ELSE 0 END) AS pts,
           SUM(goals_home) AS gf, SUM(goals_away) AS ga,
           COUNT(*) AS played
    FROM matches
    WHERE group_name != 'knock-out' AND goals_home IS NOT NULL
    GROUP BY team_home
    UNION ALL
    SELECT team_away AS team_id,
           SUM(CASE WHEN goals_away > goals_home THEN 3
                    WHEN goals_home = goals_away THEN 1 ELSE 0 END) AS pts,
           SUM(goals_away) AS gf, SUM(goals_home) AS ga,
           COUNT(*) AS played
    FROM matches
    WHERE group_name != 'knock-out' AND goals_home IS NOT NULL
    GROUP BY team_away
),
totals AS (
    SELECT team_id, SUM(pts) AS pts, SUM(gf) AS gf,
           SUM(ga) AS ga, SUM(gf) - SUM(ga) AS gd, SUM(played) AS played
    FROM results GROUP BY team_id
),
ranked AS (
    SELECT t.country, totals.*,
           DENSE_RANK() OVER (ORDER BY pts DESC, gd DESC, gf DESC) AS pos
    FROM totals JOIN teams t ON totals.team_id = t.team_id
)
SELECT * FROM ranked ORDER BY pos;
```

Pattern: raw rows → totals (SUM+GROUP BY) → ranked (DENSE_RANK) → outer filter.
Never use `SUM() OVER (PARTITION BY)` inside a CTE — causes duplicate rows in SQLite.
**`group_name != 'knock-out'` replaces the old `group_name IS NOT NULL` filter** — group_name is never NULL anymore, so the old filter is a no-op that would let knockout results leak into group standings.

### LEFT JOIN COUNT Rule

```sql
SELECT t.country, COUNT(p.player_id) AS player_count
FROM teams t
LEFT JOIN players p ON t.team_id = p.team_id
GROUP BY t.team_id, t.country;
```

COUNT(p.player_id) returns 0 for unmatched rows. COUNT(*) returns 1 — always wrong in LEFT JOINs.

---

## Quality Bar

A standings table or leaderboard must be publishable without edits:
- Correct column names (country not team_id, pos not intl_rank)
- Ties handled correctly by DENSE_RANK (no gap after tied rows)
- NULL scores excluded (`WHERE goals_home IS NOT NULL`)
- Knockout rows excluded from group-stage aggregates (`group_name != 'knock-out'`)
- Sorted correctly (pts DESC, gd DESC, gf DESC for standings)

If you wouldn't publish it as the official Group A table, it's not done.

---

## Known Issues — confirm before relying on these

- The old proxy note ("golden-boot uses `players.intl_goals` until `player_stats` is populated", "Cristiano Ronaldo missing from seed data") predates the current schema and the FBref load pipeline documented in CLAUDE.md. `player_stats` is the real source now — **confirm current row counts before assuming the proxy is still needed**, and delete this note once confirmed dead.
- CLAUDE.md's FBref Pipeline section resolves identity via `players.fbref_id` and `matches.fbref_match_id`, but neither column appears in CLAUDE.md's own Database Schema block above the pipeline section — worth reconciling in CLAUDE.md itself, not just here.

---

*Rewritten 2026-07-06 to match the current CLAUDE.md schema — added `pk_home/away`, `corners_home/away`, `possession_home/away`, `match_time`, `attendance`, `referee` to `matches`; added `shirt_number`, `footed`, `birthday`, `birthplace`, `league`, `matches_played/started`, career stat columns to `players`; replaced `age`/`caps`/`intl_goals` (not in current schema); added `appearances`/`best_finish` to `teams`, removed `squad_size`/`avg_age` (not in current schema); added full `player_stats` column list; added `goalkeeper_stats` (was entirely absent); fixed the `group_name IS NOT NULL` → `!= 'knock-out'` bug; added `worldcup26_results.sql` throughout the seed/live rules and rebuild command (was not mentioned at all in the previous version).*
