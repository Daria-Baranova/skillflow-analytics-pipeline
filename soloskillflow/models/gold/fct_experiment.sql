WITH funnel AS (
    SELECT * FROM {{ ref('fct_funnel') }}
    WHERE NOT is_test_account
),

paid AS (
    SELECT DISTINCT user_id 
    FROM {{ ref('fct_subscriptions') }} 
    WHERE is_converted
),

returned_d1 AS (
    SELECT DISTINCT user_id
    FROM {{ ref('fct_user_activity') }}
    WHERE days_since_signup = 1
),

erors AS (
    SELECT DISTINCT user_id
    FROM {{ ref('stg_app_errors') }}
),

tickets AS (
    SELECT DISTINCT user_id
    FROM {{ ref('stg_support_tickets')}}
),

final AS (
    SELECT
        f.user_id
        , f.experiment_group
        , f.trial_activated_at IS NOT NULL      AS is_trial
        , p.user_id IS NOT NULL                 AS is_paid
        , f.is_activated
        , r.user_id IS NOT NULL                 AS is_returned_d1
        , f.onboarding_completed_at IS NOT NULL AS is_onboarding_completed
        , e.user_id IS NOT NULL                 AS had_app_error
        , t.user_id IS NOT NULL                 AS had_support_ticket
    FROM funnel AS f 
    LEFT JOIN paid          AS p ON p.user_id = f.user_id
    LEFT JOIN returned_d1   AS r ON r.user_id = f.user_id
    LEFT JOIN erors         AS e ON e.user_id = f.user_id
    LEFT JOIN tickets       AS t ON t.user_id = f.user_id
)

SELECT *
FROM final