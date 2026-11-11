-- Правило: на кожному кроці воронки людей не більше, ніж на попередньому.
WITH steps AS (
    SELECT step_order, count(*) AS users
    FROM {{ ref('fct_funnel_steps') }}
    GROUP BY 1
)
SELECT *
FROM (
    SELECT
          step_order
        , users
        , lag(users) OVER (ORDER BY step_order) AS prev_users
    FROM steps
) AS t
WHERE users > prev_users