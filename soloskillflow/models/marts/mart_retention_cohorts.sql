-- Когорти за тижнем реєстрації: одна когорта = один рядок.
-- Адитивні колонки *_eligible і *_returned: підсумок = SUM(returned) / SUM(eligible).
WITH users AS (
    SELECT * FROM {{ ref('mart_users') }}
),

activity AS (
    SELECT DISTINCT user_id, days_since_signup
    FROM {{ ref('mart_user_activity_daily') }}
),

data_end AS (
    SELECT max(activity_date) AS max_date
    FROM {{ ref('mart_user_activity_daily') }}
),

counts AS (
    SELECT
          u.signup_week
        , count(*)                                                       AS cohort_size
        -- eligible: день N уже настав; returned: був активний у день N
        , count(*) FILTER (WHERE u.signup_date + 1  <= e.max_date)       AS d1_eligible
        , count(d1.user_id)                                              AS d1_returned
        , count(*) FILTER (WHERE u.signup_date + 7  <= e.max_date)       AS d7_eligible
        , count(d7.user_id)                                              AS d7_returned
        , count(*) FILTER (WHERE u.signup_date + 14 <= e.max_date)       AS d14_eligible
        , count(d14.user_id)                                             AS d14_returned
    FROM users AS u
    CROSS JOIN data_end AS e
    LEFT JOIN activity AS d1  ON d1.user_id  = u.user_id AND d1.days_since_signup  = 1
    LEFT JOIN activity AS d7  ON d7.user_id  = u.user_id AND d7.days_since_signup  = 7
    LEFT JOIN activity AS d14 ON d14.user_id = u.user_id AND d14.days_since_signup = 14
    GROUP BY 1
)

SELECT
      *
    -- відсотки лише для зручного читання таблиці
    , round(100.0 * d1_returned  / nullif(d1_eligible, 0), 1)  AS d1_retention_pct
    , round(100.0 * d7_returned  / nullif(d7_eligible, 0), 1)  AS d7_retention_pct
    , round(100.0 * d14_returned / nullif(d14_eligible, 0), 1) AS d14_retention_pct
FROM counts