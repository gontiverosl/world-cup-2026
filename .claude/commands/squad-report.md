---
description: Full squad breakdown for a World Cup 2026 team
argument-hint: <team_id or country, e.g. MEX or Mexico>
---

Generate a full squad report for **$ARGUMENTS** from `worldcup26.db`.

Steps:

1. **Resolve the team.** The argument may be a 3-letter FIFA `team_id` (e.g. `MEX`) or a country name (e.g. `Mexico`). Match on either:
   ```sql
   SELECT team_id, country, group_name, fifa_ranking, coach
   FROM teams
   WHERE team_id = ? OR country = ?;
   ```
   If nothing matches, say so and suggest the closest team names. Never guess silently.

2. **List the squad**, grouped and ordered by position in football order — GK, then DF, then MF, then FW — and within each position by `caps DESC`:
   ```sql
   SELECT name, position, age, club, caps, intl_goals
   FROM players
   WHERE team_id = ?
   ORDER BY CASE position WHEN 'GK' THEN 1 WHEN 'DF' THEN 2
                          WHEN 'MF' THEN 3 WHEN 'FW' THEN 4 ELSE 5 END,
            caps DESC;
   ```

3. **Summary block:** total players, average age (round to 1 decimal), most-capped player, top scorer by `intl_goals`, and number of distinct clubs represented.

Conventions: `?` placeholders only (never f-strings in SQL); JOIN to `teams` for any display name. Output a clean position-grouped table plus the summary. Quality bar: a one-page squad sheet you'd hand to a CFO — or post before a match.
