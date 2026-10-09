WITH users AS (
    SELECT * FROM {{ ref('dim_users') }}
),

events AS (
    SELECT * FROM {{ ref('stg_events') }}
),

first_steps AS (
    SELECT 
        user_id
        , MIN(event_ts) FILTER (WHERE event_name = 'signup')                AS signup_at 
        , MIN(event_ts) FILTER (WHERE event_name = 'onboarding_started')    AS onboarding_started_at
        , MIN(event_ts) FILTER (WHERE event_name = 'onboarding_completed')  AS onboarding_completed_at
        , MIN(event_ts) FILTER (WHERE event_name = 'paywall_viewed')        AS paywall_viewed_at
        , MIN(event_ts) FILTER (WHERE event_name = 'trial_activated')       AS trial_activated_at
        , MIN(event_ts) FILTER (WHERE event_name = 'lesson_started')        AS lesson_started_at
        , MIN(event_ts) FILTER (WHERE event_name = 'lesson_completed')      AS lesson_completed_at
    FROM events
    GROUP BY 1
),

final AS (
    SELECT
        u.user_id
        , u.signup_week
        , u.traffic_source
        , u.experiment_group
        , u.is_test_account
        , f.signup_at
        , f.onboarding_started_at
        , f.onboarding_completed_at
        , f.paywall_viewed_at
        , f.trial_activated_at
        , f.lesson_started_at
        , f.lesson_completed_at
        , f.lesson_completed_at IS NOT NULL AS is_activated
        , CASE
              WHEN f.lesson_completed_at >= f.signup_at
              THEN round(extract(EPOCH FROM f.lesson_completed_at - f.signup_at) / 3600, 1)
          END AS hours_to_first_value 
    FROM users AS u 
    LEFT JOIN first_steps AS f 
        ON f.user_id = u.user_id
)

SELECT *
FROM final