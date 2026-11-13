{#- допуск на відомий зсув часу подій: "призначення мінус N годин" -#}
{%- set tolerance = "INTERVAL '" ~ var('event_time_tolerance_hours') ~ " hours'" -%}

-- Учасники основного A/B-тесту: один рядок = реальний користувач.
-- Результати рахуємо лише ПІСЛЯ призначення в групу (з допуском на зсув часу).
WITH assignments AS (
    SELECT experiment_id, user_id, experiment_group, assigned_at
    FROM {{ ref('dim_experiment_assignments') }}
    WHERE experiment_id = '{{ var("main_experiment_id") }}'
      AND has_conflicting_groups IS NOT TRUE
),

users AS (
    SELECT * FROM {{ ref('mart_users') }}
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
    FROM {{ ref('mart_user_activity_daily') }}
    WHERE days_since_signup = 1
),

errors AS (
    SELECT user_id, occurred_at FROM {{ ref('fct_app_errors') }}
),

tickets AS (
    SELECT user_id, created_at FROM {{ ref('fct_support_tickets') }}
),

final AS (
    SELECT
          a.experiment_id
        , a.user_id
        , a.experiment_group
        , a.assigned_at
        -- сегменти для аналізу
        , u.signup_week
        , u.traffic_source
        , u.country
        , u.device
        -- primary metric
        , coalesce(u.trial_activated_at >= a.assigned_at - {{ tolerance }}, false)       AS is_trial
        -- secondary metrics
        , coalesce(p.first_payment_at >= a.assigned_at - {{ tolerance }}, false)         AS is_paid
        , coalesce(u.lesson_completed_at >= a.assigned_at - {{ tolerance }}, false)      AS is_activated
        , r.user_id IS NOT NULL                                                          AS is_returned_d1
        -- guardrails
        , coalesce(u.onboarding_completed_at >= a.assigned_at - {{ tolerance }}, false)  AS is_onboarding_completed
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
    INNER JOIN users AS u
        ON u.user_id = a.user_id     -- INNER: лише реальні користувачі
    LEFT JOIN paid        AS p ON p.user_id = a.user_id
    LEFT JOIN returned_d1 AS r ON r.user_id = a.user_id
)

SELECT *
FROM final