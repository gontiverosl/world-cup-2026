/* 
Spec: Golden boot leaderboard using player_stats. 
Two CTEs: 
(1) aggregate total goals per player_id using SUM() + GROUP BY, 
(2) outer query applies DENSE_RANK() OVER (ORDER BY total_goals DESC).
JOIN to players for name, to teams for country. 
Filter: only rows where goals > 0.
*/

WITH ranked AS (
    SELECT
    name,
    team_id,
    position,
    age,
    DENSE_RANK() OVER (PARTITION BY position ORDER BY age ASC) AS age_rank
FROM players
)
SELECT
    name,
    team_id,
    position,
    age,
    age_rank
FROM ranked
WHERE age_rank = 1;