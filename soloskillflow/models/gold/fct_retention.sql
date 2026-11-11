WITH users AS (
    SELECT * FROM {{ ref('dim_users') }}
    WHERE is_test_account IS NOT TRUE
),

activity AS (
    SELECT 
        DISTINCT user_id
        , days_since_signup
    FROM {{ ref('fct_user_activity') }}
),

data_end AS (
    SELECT MAX(activity_date) AS max_date
    FROM {{ ref('fct_user_activity') }}
),

final AS (
    SELECT
        u.signup_week
        , COUNT(*)          AS cohort_size
        , ROUND(100.0 * COUNT(d1.user_id) 
            / NULLIF(COUNT(*) FILTER (WHERE u.signup_date + 1 <= e.max_date), 0), 1)    AS d1_retention_pct
        , ROUND(100.0 * COUNT(d7.user_id) 
            / NULLIF(COUNT(*) FILTER (WHERE u.signup_date + 7 <= e.max_date), 0) ,1)    AS d7_retention_pct
        , ROUND(100.0 * COUNT(d14.user_id) 
            / NULLIF(COUNT(*) FILTER (WHERE u.signup_date + 14 <= e.max_date), 0) ,1)   AS d14_retention_pct
    FROM users AS u 
    CROSS JOIN data_end AS e 
    LEFT JOIN activity AS d1    ON d1.user_id = u.user_id   AND d1.days_since_signup = 1
    LEFT JOIN activity AS d7    ON d7.user_id = u.user_id   AND d7.days_since_signup = 7
    LEFT JOIN activity AS d14   ON d14.user_id = u.user_id  AND d14.days_since_signup = 14
    GROUP BY 1
)

SELECT *
FROM final
ORDER BY signup_week