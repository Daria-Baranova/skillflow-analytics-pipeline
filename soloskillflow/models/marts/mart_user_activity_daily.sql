-- Вітрина активності: один рядок = реальний користувач × день, коли він був активний.
-- Основа для DAU / WAU / MAU, stickiness і "нові vs повернулися".
WITH users AS (
    SELECT * FROM {{ ref('mart_users') }}
),

activity AS (
    SELECT * FROM {{ ref('fct_user_activity') }}
),

final AS (
    SELECT
          a.user_id
        , a.activity_date
        , a.activity_date - u.signup_date                      AS days_since_signup
        -- бізнес-правило живе в dbt, а не в Superset
        , CASE
              WHEN a.activity_date = u.signup_date THEN 'New users'
              ELSE 'Returning users'
          END                                                   AS user_type
        , u.signup_date
        , u.signup_week
        , u.traffic_source
        , u.experiment_group
        , u.country
        , a.events_count
        , a.sessions_count
    FROM activity AS a
    INNER JOIN users AS u
        ON u.user_id = a.user_id     -- INNER: лише реальні користувачі
    WHERE a.activity_date >= u.signup_date
)

SELECT *
FROM final