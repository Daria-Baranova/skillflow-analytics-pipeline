-- Вітрина підписок: один рядок = одна підписка реального користувача.
WITH subscriptions AS (
    SELECT * FROM {{ ref('fct_subscriptions') }} AS s
    WHERE {{ is_real_user('s.user_id') }}
),

users AS (
    SELECT user_id, signup_week, traffic_source, country, experiment_group
    FROM {{ ref('mart_users') }}
),

plans AS (
    SELECT * FROM {{ ref('dim_plans') }}
),

final AS (
    SELECT
          s.subscription_id
        , s.user_id
        , s.plan
        , pl.plan_order
        , s.trial_status
        , s.trial_started_at
        , s.converted_at
        , s.cancelled_at
        , s.is_converted
        , s.is_trial_finished
        , s.first_payment_at
        , s.plan_prise_usd      AS plan_price_usd        -- виправлена назва
        , s.monthly_values_usd  AS monthly_value_usd     -- виправлена назва
        , s.net_revenue_usd
        , s.has_refund
        , u.signup_week
        , u.traffic_source
        , u.country
        , u.experiment_group
    FROM subscriptions AS s
    LEFT JOIN users AS u ON u.user_id  = s.user_id
    LEFT JOIN plans AS pl ON pl.plan   = s.plan
)

SELECT *
FROM final