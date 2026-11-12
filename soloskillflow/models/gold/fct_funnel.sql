WITH users AS (
    SELECT * FROM {{ ref('dim_users') }}
),

first_steps AS (
    SELECT * FROM {{ ref('int_user_first_steps') }}
),

final AS (
    SELECT
        u.user_id
        , u.signup_week
        , u.traffic_source
        , u.experiment_group
        , u.is_test_account
        , u.signup_at                     -- єдине джерело правди: таблиця users
        , f.onboarding_started_at
        , f.onboarding_completed_at
        , f.paywall_viewed_at
        , f.trial_activated_at
        , f.lesson_started_at
        , f.lesson_completed_at
        , f.lesson_completed_at IS NOT NULL AS is_activated
        -- биті дані: урок завершено раніше за реєстрацію → TTFV невідомий
        , coalesce(f.lesson_completed_at < u.signup_at, false) AS has_invalid_ttfv
        , CASE
              WHEN f.lesson_completed_at >= u.signup_at
              THEN round(extract(EPOCH FROM f.lesson_completed_at - u.signup_at) / 3600, 1)
          END AS hours_to_first_value 
    FROM users AS u 
    LEFT JOIN first_steps AS f 
        ON f.user_id = u.user_id
)

SELECT *
FROM final