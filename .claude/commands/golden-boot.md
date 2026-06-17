---
description: Tournament golden-boot leaderboard (DENSE_RANK by goals)
argument-hint: [top N, default 10]
---

Produce the World Cup 2026 golden-boot leaderboard (top **${ARGUMENTS:-10}** scorers) from `worldcup26.db`.

**First, check the data dependency.** The tournament golden boot is computed from per-match goals, which live in a `player_stats` table (WC26 Phase 2). Run:

```sql
SELECT name FROM sqlite_master WHERE type='table' AND name='player_stats';
```

**If `player_stats` exists**, build the leaderboard with the standard pattern — aggregate in a CTE, rank in the outer query (SQLite can't nest window functions):

```sql
WITH goals AS (
    SELECT player_id, SUM(goals) AS tournament_goals
    FROM player_stats
    GROUP BY player_id
)
SELECT p.name, t.country, g.tournament_goals,
       DENSE_RANK() OVER (ORDER BY g.tournament_goals DESC) AS rank
FROM goals g
JOIN players p ON g.player_id = p.player_id
JOIN teams   t ON p.team_id   = t.team_id
WHERE g.tournament_goals > 0
ORDER BY rank, p.name
LIMIT ?;
```

Use `DENSE_RANK()` (not `RANK()`) so tied scorers share a rank with no gaps after them.

**If `player_stats` does NOT exist yet**, do not fabricate tournament goals. Say clearly that tournament scoring isn't tracked yet (it's WC26 Phase 2), then offer the closest available stand-in — the career international-goals leaderboard — and label it as such:

```sql
SELECT p.name, t.country, p.intl_goals,
       DENSE_RANK() OVER (ORDER BY p.intl_goals DESC) AS rank
FROM players p
JOIN teams t ON p.team_id = t.team_id
ORDER BY rank, p.name
LIMIT ?;
```

`?` placeholders only. Quality bar: a leaderboard you'd publish — clearly labelled as tournament goals vs career goals so no one is misled.
