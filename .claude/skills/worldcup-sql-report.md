# WC26 SQL Report Patterns

Domain knowledge for worldcup26.db queries. Read alongside CLAUDE.md.

---

## Schema Quick Reference

```
teams        — team_id (PK, 3-letter FIFA code), country, confederation,
               group_name ('A'–'L'), fifa_ranking, coach, host, squad_size,
               avg_age, market_value_m, base_camp

players      — player_id (PK AUTOINCREMENT), team_id (FK), name,
               position (GK/DF/MF/FW), age, club, caps, intl_goals

matches      — match_id (PK AUTOINCREMENT), fifa_match_no (UNIQUE),
               team_home (FK, NULL if knockout team not yet known),
               team_away (FK, NULL if knockout team not yet known),
               goals_home (NULL = not yet played),
               goals_away (NULL = not yet played),
               stage ('group'/'r32'/'r16'/'qf'/'sf'/'third_place'/'final'),
               group_name (NULL for knockout), match_date (ISO 'YYYY-MM-DD'),
               stadium, city

player_stats — stat_id (PK AUTOINCREMENT), player_id (FK), match_id (FK),
               goals, assists, minutes_played, yellow_cards, red_cards,
               shots, shots_on_goal, fouls
               UNIQUE (player_id, match_id)
```

---

## The NULL Rules

**goals_home / goals_away IS NULL = match not yet played.**
Every standings and stats query must filter: `WHERE goals_home IS NOT NULL`

**team_home / team_away IS NULL = knockout teams not yet determined.**
Knockout bracket slots are pre-inserted with NULL teams. Assign teams once qualifying results are in.

**matches stores team_id codes, never country names.**
Always JOIN to teams for display: `JOIN teams t ON m.team_home = t.team_id`

---

## Seed vs Live DB Rules

| What | Where |
|------|-------|
| Schema changes (new tables, columns) | worldcup26_seed.sql FIRST, then rebuild |
| Match scores (goals_home, goals_away) | Live DB only via UPDATE — never in seed |
| Knockout team assignments | Live DB only via UPDATE |
| Squad data, team data | worldcup26_seed.sql |

Rebuild command: `sqlite3 worldcup26.db < worldcup26_seed.sql`
Rebuilding wipes all match scores — that is intentional. Re-run daily-update task to restore.

---

## Standard Query Patterns

### Golden Boot / Leaderboard (DENSE_RANK)

```sql
WITH ranked AS (
    SELECT
        p.name,
        t.country,
        ps.goals AS tournament_goals,
        DENSE_RANK() OVER (ORDER BY ps.goals DESC) AS rank
    FROM player_stats ps
    JOIN players p ON ps.player_id = p.player_id
    JOIN teams t ON p.team_id = t.team_id
    GROUP BY ps.player_id
)
SELECT * FROM ranked WHERE rank <= 10;
```

- Use DENSE_RANK(), never RANK() — no gaps after ties
- Window alias not usable in WHERE — always wrap in CTE and filter in outer query
- Until player_stats is populated, intl_goals from players is a career proxy only

### Group Standings (Multi-CTE)

```sql
WITH results AS (
    SELECT team_home AS team_id,
           SUM(CASE WHEN goals_home > goals_away THEN 3
                    WHEN goals_home = goals_away THEN 1 ELSE 0 END) AS pts,
           SUM(goals_home) AS gf, SUM(goals_away) AS ga,
           COUNT(*) AS played
    FROM matches
    WHERE group_name IS NOT NULL AND goals_home IS NOT NULL
    GROUP BY team_home
    UNION ALL
    SELECT team_away AS team_id,
           SUM(CASE WHEN goals_away > goals_home THEN 3
                    WHEN goals_home = goals_away THEN 1 ELSE 0 END) AS pts,
           SUM(goals_away) AS gf, SUM(goals_home) AS ga,
           COUNT(*) AS played
    FROM matches
    WHERE group_name IS NOT NULL AND goals_home IS NOT NULL
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
Never use SUM() OVER (PARTITION BY) inside a CTE — causes duplicate rows in SQLite.

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
- NULL scores excluded (WHERE goals_home IS NOT NULL)
- Sorted correctly (pts DESC, gd DESC, gf DESC for standings)

If you wouldn't publish it as the official Group A table, it's not done.

---

## Known Proxy / Pending Issues

- `intl_goals` in players = career international goals (seed data), not WC26 tournament goals
- Tournament goals require player_stats table — populate after each match
- `/golden-boot` slash command uses intl_goals as proxy until player_stats is built
- Cristiano Ronaldo missing from players seed data — add before player_stats work begins
