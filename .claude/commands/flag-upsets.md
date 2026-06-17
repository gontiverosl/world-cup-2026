---
description: Flag played results where the lower FIFA-ranked team won
argument-hint: [group letter, optional — omit for the whole tournament]
---

Find the upsets in `worldcup26.db` — played matches where the team with the **worse** FIFA ranking beat the better-ranked team. Scope: group **$ARGUMENTS** if a letter is given, otherwise the whole tournament.

Key facts:
- `fifa_ranking` is an integer where **lower = better** (rank 1 is the best team). An upset = the winner's `fifa_ranking` number is **higher** than the loser's.
- Only consider played matches: `WHERE goals_home IS NOT NULL`.
- `matches` stores `team_id` only — JOIN to `teams` twice (home + away) for names and rankings.

Reference pattern:

```sql
SELECT m.match_date,
       hm.country AS home, m.goals_home,
       am.country AS away, m.goals_away,
       hm.fifa_ranking AS home_rank,
       am.fifa_ranking AS away_rank,
       CASE
           WHEN m.goals_home > m.goals_away AND hm.fifa_ranking > am.fifa_ranking
               THEN hm.country || ' upset ' || am.country
           WHEN m.goals_away > m.goals_home AND am.fifa_ranking > hm.fifa_ranking
               THEN am.country || ' upset ' || hm.country
           ELSE NULL
       END AS upset
FROM matches m
JOIN teams hm ON m.team_home = hm.team_id
JOIN teams am ON m.team_away = am.team_id
WHERE m.goals_home IS NOT NULL
  -- AND m.group_name = ?        -- include only when a group letter is supplied
ORDER BY ABS(hm.fifa_ranking - am.fifa_ranking) DESC, m.match_date;
```

Return only the rows where `upset IS NOT NULL`, sorted by the size of the ranking gap (biggest shock first). For each, show the score, both rankings, and the gap. CASE WHEN rule: most specific condition first, AND-join the two conditions — a missing condition gives silently wrong output. If a group letter was supplied, add the `group_name = ?` filter with a `?` placeholder. If there are no upsets in scope, say so. Quality bar: a "shocks so far" table you'd publish.
