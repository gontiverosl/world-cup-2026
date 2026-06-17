---
description: Current standings (W/D/L/GF/GA/GD/Pts) for one World Cup 2026 group
argument-hint: <group letter A-L>
---

Build the current group-stage standings table for group **$ARGUMENTS** from `worldcup26.db`.

Follow the WC26 conventions in `CLAUDE.md`:

1. **Only count played matches** — `goals_home`/`goals_away` are NULL until a match is played. Every standings query must filter `WHERE goals_home IS NOT NULL`.
2. **Points:** 3 for a win, 1 for a draw, 0 for a loss. Compute per team: Played, W, D, L, GF (goals for), GA (goals against), GD (GF − GA), Pts.
3. **Names, not codes:** `matches` stores `team_id` references only. JOIN to `teams` for `country`.
4. **Tiebreak order:** `ORDER BY Pts DESC, GD DESC, GF DESC, country ASC`.
5. Use a CTE that UNIONs home and away rows, then aggregate with `SUM() + GROUP BY` (never `SUM() OVER (PARTITION BY)` — that duplicates rows).

Reference pattern:

```sql
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
       COUNT(*)        AS played,
       SUM(p.w)        AS w,
       SUM(p.d)        AS d,
       SUM(p.l)        AS l,
       SUM(p.gf)       AS gf,
       SUM(p.ga)       AS ga,
       SUM(p.gf) - SUM(p.ga) AS gd,
       SUM(p.pts)      AS pts
FROM played p
JOIN teams t ON p.team = t.team_id
GROUP BY p.team
ORDER BY pts DESC, gd DESC, gf DESC, t.country ASC;
```

Use a `?` placeholder for the group letter — never an f-string. Print a clean, aligned standings table with a header. If the group has no played matches yet, say so plainly and list the four teams in the group with all zeros. Quality bar: a table you'd be comfortable publishing.
