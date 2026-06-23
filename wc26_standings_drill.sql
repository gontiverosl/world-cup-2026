/* 
Spec: Write a group standings query for worldcup26.db — specifically Group A. 
Three CTEs chained: 
(1) a results CTE that unpacks each match into two team rows (home + away), 
(2) a totals CTE that sums points/GD/GF per team, 
(3) an outer query that applies DENSE_RANK() OVER (ORDER BY pts DESC, gd DESC, gf DESC). 
Filter WHERE goals_home IS NOT NULL. JOIN to teams for country. No SUM() OVER (PARTITION BY) inside a CTE.
*/

WITH results AS (
    SELECT
        team_home AS team_id,
        goals_home AS gf,
        goals_away AS ga,
        group_name
    FROM matches 
    WHERE group_name = 'A' AND goals_home IS NOT NULL
    UNION ALL
    SELECT 
        team_away AS team_id, 
        goals_away AS gf,
        goals_home AS ga,
        group_name
    FROM matches
    WHERE group_name = 'A' AND goals_home IS NOT NULL
),
totals AS (
    SELECT    
        r.team_id,
        t.country,
        SUM(r.gf) AS gf_total,
        SUM(r.ga) AS ga_total,
        SUM(CASE WHEN r.gf > r.ga THEN 3
                 WHEN r.gf = r.ga THEN 1
                 ELSE 0
            END) AS pts,
        SUM(r.gf - r.ga) AS gd,
        r.group_name
    FROM results r JOIN teams t ON t.team_id = r.team_id   
    GROUP BY r.team_id, t.country, r.group_name     
)
SELECT
    team_id,
    country,
    gf_total,
    ga_total,
    pts,
    gd,
    group_name,
    DENSE_RANK() OVER (ORDER BY pts DESC, gd DESC, gf_total DESC) AS rank
FROM totals;