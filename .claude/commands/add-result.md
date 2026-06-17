---
description: Scaffold + safely apply the UPDATE that records a played match result
argument-hint: <match_id> <goals_home> <goals_away>  — or describe the fixture
---

Record a match result in `worldcup26.db`. Input: **$ARGUMENTS** (either `<match_id> <goals_home> <goals_away>`, or a plain-English fixture like "Mexico 2 - 1 South Korea").

**Confirm before you write — never UPDATE blind.**

1. **Identify the exact match first.** If given a `match_id`, SELECT it to confirm. If given team names/codes, resolve them and find the fixture:
   ```sql
   SELECT m.match_id, hm.country AS home, am.country AS away,
          m.goals_home, m.goals_away, m.group_name, m.match_date
   FROM matches m
   JOIN teams hm ON m.team_home = hm.team_id
   JOIN teams am ON m.team_away = am.team_id
   WHERE m.match_id = ?;          -- or: WHERE m.team_home = ? AND m.team_away = ?
   ```
   Show the matched row. If zero or more than one row matches, stop and ask — do not write.

2. **Watch home/away orientation.** `goals_home` belongs to `team_home`, `goals_away` to `team_away`. If the user phrased it in the opposite order, map the scores to the correct columns and call it out.

3. **Scaffold the parameterized UPDATE** (the daily-update pattern from `CLAUDE.md`):
   ```sql
   UPDATE matches
   SET goals_home = ?, goals_away = ?
   WHERE match_id = ?;
   ```
   ```python
   conn = None
   try:
       conn = sqlite3.connect(DB_PATH)
       cur = conn.cursor()
       cur.execute("UPDATE matches SET goals_home = ?, goals_away = ? WHERE match_id = ?",
                   (goals_home, goals_away, match_id))
       conn.commit()                       # required — SQLite rolls back silently without it
       print(f"Rows updated: {cur.rowcount}")   # expect exactly 1
   finally:
       if conn:
           conn.close()
   ```

4. **Verify:** confirm `rowcount == 1`, then re-SELECT the row to show the new score. Remind that corrections to seeded data also belong in `worldcup26_seed.sql`.

`?` placeholders only — never f-strings. Don't run the UPDATE until the matched row is confirmed.
