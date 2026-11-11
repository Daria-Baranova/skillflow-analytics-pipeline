{#- допуск на відомий зсув часу подій: "призначення мінус N годин" -#}
{%- set tolerance = "INTERVAL '" ~ var('event_time_tolerance_hours') ~ " hours'" -%}

WITH assignments AS (
    -- учасники без порушених призначень
    SELECT * FROM {{ ref('stg_experiments') }}
    WHERE has_conflicting_groups IS NOT TRUE
),

users AS (
    SELECT user_id FROM {{ ref('dim_users') }}
    WHERE is_test_account IS NOT TRUE
),

funnel AS (
    SELECT * FROM {{ ref('fct_funnel') }}
),

-- оплата = перший реальний платіж
paid AS (
    SELECT user_id, min(first_payment_at) AS first_payment_at
    FROM {{ ref('fct_subscriptions') }}
    WHERE first_payment_at IS NOT NULL
    GROUP BY 1
),

returned_d1 AS (
    SELECT DISTINCT user_id
    FROM {{ ref('fct_user_activity') }}
    WHERE days_since_signup = 1
),

errors AS (
    SELECT user_id, occurred_at FROM {{ ref('stg_app_errors') }}
),

tickets AS (
    SELECT user_id, created_at FROM {{ ref('stg_support_tickets') }}
),

-- рахуємо лише події ПІСЛЯ призначення в групу
final AS (
    SELECT
          a.experiment_id
        , a.user_id
        , a.experiment_group
        , a.assigned_at
        -- primary metric
        , coalesce(f.trial_activated_at >= a.assigned_at - {{ tolerance }}, false)       AS is_trial
        -- secondary metrics
        , coalesce(p.first_payment_at >= a.assigned_at - {{ tolerance }}, false)         AS is_paid
        , coalesce(f.lesson_completed_at >= a.assigned_at - {{ tolerance }}, false)      AS is_activated
        , r.user_id IS NOT NULL                                                          AS is_returned_d1
        -- guardrails
        , coalesce(f.onboarding_completed_at >= a.assigned_at - {{ tolerance }}, false)  AS is_onboarding_completed
        , EXISTS (
              SELECT 1 FROM errors AS e
              WHERE e.user_id = a.user_id
                AND e.occurred_at >= a.assigned_at - {{ tolerance }}
          )                                                                              AS had_app_error
        , EXISTS (
              SELECT 1 FROM tickets AS t
              WHERE t.user_id = a.user_id
                AND t.created_at >= a.assigned_at - {{ tolerance }}
          )                                                                              AS had_support_ticket
    FROM assignments AS a
    INNER JOIN users AS u ON u.user_id = a.user_id
    LEFT JOIN funnel      AS f ON f.user_id = a.user_id
    LEFT JOIN paid        AS p ON p.user_id = a.user_id
    LEFT JOIN returned_d1 AS r ON r.user_id = a.user_id
)

SELECT *
FROM final