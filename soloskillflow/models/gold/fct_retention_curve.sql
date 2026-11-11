WITH users AS (
    SELECT 
        user_id
        , signup_date 
    FROM {{ ref('dim_users') }}
    WHERE is_test_account IS NOT TRUE
),

activity AS (
    SELECT 
        DISTINCT user_id
        , days_since_signup
    FROM {{ ref('fct_user_activity') }}
    WHERE is_test_account IS NOT TRUE
),

data_end AS (
    SELECT MAX(activity_date) AS max_date FROM {{ ref('fct_user_activity') }}
),

days AS (
    SELECT generate_series(0, 20) AS day_n
),

final AS (
    SELECT
        d.day_n
        , COUNT(*) FILTER (WHERE u.signup_date + d.day_n <= e.max_date) AS eligible_users
        , COUNT(a.user_id)                                              AS returned_users
    FROM days AS d
    CROSS JOIN users AS u
    CROSS JOIN data_end AS e
    LEFT JOIN activity AS a
        ON a.user_id = u.user_id 
        AND a.days_since_signup = d.day_n
    GROUP BY 1
)

SELECT
    day_n
    , eligible_users
    , returned_users
    , ROUND(100.0 * returned_users / NULLIF(eligible_users, 0), 1) AS retention_pct
FROM final