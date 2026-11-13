-- Крива retention: один рядок = день N після реєстрації (0..20).
-- Адитивні колонки: eligible_users і returned_users.
WITH users AS (
    SELECT user_id, signup_date FROM {{ ref('mart_users') }}
),

activity AS (
    SELECT DISTINCT user_id, days_since_signup
    FROM {{ ref('mart_user_activity_daily') }}
),

data_end AS (
    SELECT max(activity_date) AS max_date
    FROM {{ ref('mart_user_activity_daily') }}
),

-- дні 0..20 (активність після 21-го дня в даних відсутня)
days AS (
    SELECT generate_series(0, 20) AS day_n
),

counts AS (
    SELECT
          d.day_n
        , count(*) FILTER (WHERE u.signup_date + d.day_n <= e.max_date) AS eligible_users
        , count(a.user_id)                                              AS returned_users
    FROM days AS d
    CROSS JOIN users AS u
    CROSS JOIN data_end AS e
    LEFT JOIN activity AS a
        ON  a.user_id = u.user_id
        AND a.days_since_signup = d.day_n
    GROUP BY 1
)

SELECT
      *
    , round(100.0 * returned_users / nullif(eligible_users, 0), 1) AS retention_pct
FROM counts