WITH rank AS (
	SELECT
		p.name,
		t.country,
		p.intl_goals,
		DENSE_RANK() OVER (ORDER BY p.intl_goals DESC) AS intl_rank
	FROM teams t
	JOIN players p ON p.team_id = t.team_id
)
SELECT *
FROM rank
WHERE intl_rank <= 10;