WITH events AS (
    SELECT * FROM {{ ref('stg_events') }}
),

users AS (
    SELECT * FROM {{ ref('dim_users') }}
),

daily AS (
    SELECT
        user_id
        , event_ts::DATE                AS  activity_date
        , COUNT(*)                      AS events_count
        , COUNT(DISTINCT session_id)    AS sessions_count
    FROM events
    GROUP BY 1, 2
),

final AS (
    SELECT
        d.user_id
        , d. activity_date
        , d.activity_date - u.signup_date   AS days_since_signup
        , u.signup_date
        , u.signup_week
        , u.experiment_group
        , u.is_test_account
        , d.events_count
        , d.sessions_count
    FROM daily AS d 
    INNER JOIN users AS u 
        ON u.user_id = d.user_id
    WHERE d.activity_date >= u.signup_date
)

SELECT *
FROM final