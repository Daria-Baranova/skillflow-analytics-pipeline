WITH funnel AS (
    SELECT * FROM {{ ref('fct_funnel') }}
    WHERE NOT is_test_account
),

users AS (
    SELECT user_id, country, device FROM {{ ref('dim_users') }}
),

long AS (
    SELECT user_id, 1 AS step_order, '1. Signup' AS step_name, signup_at IS NOT NULL AS reached FROM funnel
    UNION ALL SELECT user_id, 2, '2. Onboarding started',   onboarding_started_at   IS NOT NULL FROM funnel
    UNION ALL SELECT user_id, 3, '3. Onboarding completed', onboarding_completed_at IS NOT NULL FROM funnel
    UNION ALL SELECT user_id, 4, '4. Paywall viewed',       paywall_viewed_at       IS NOT NULL FROM funnel
    UNION ALL SELECT user_id, 5, '5. Trial activated',      trial_activated_at      IS NOT NULL FROM funnel
    UNION ALL SELECT user_id, 6, '6. Lesson started',       lesson_started_at       IS NOT NULL FROM funnel
    UNION ALL SELECT user_id, 7, '7. Lesson completed',     lesson_completed_at     IS NOT NULL FROM funnel
),

strict AS (
    SELECT
          *
        , bool_and(reached) OVER (PARTITION BY user_id ORDER BY step_order) AS reached_strict
    FROM long
),

final AS (
    SELECT
          s.user_id
        , s.step_order
        , s.step_name
        , f.signup_week
        , f.traffic_source
        , f.experiment_group
        , u.country
        , u.device
    FROM strict AS s
    INNER JOIN funnel AS f ON f.user_id = s.user_id
    LEFT JOIN users  AS u ON u.user_id = s.user_id
    WHERE s.reached_strict
)

SELECT *
FROM final