WITH subscriptions AS (
    SELECT * FROM {{ ref('stg_subscriptions') }}
),

users AS (
    SELECT * FROM {{ ref('dim_users') }}
),

plans AS (
    SELECT * FROM {{ ref('dim_plans') }}
),

payments AS (
    SELECT
        subscription_id
        , MIN(paid_at) FILTER (WHERE NOT is_refund)     AS first_payment_at
        , MIN(amount_usd) FILTER (WHERE NOT is_refund)  AS plan_prise_usd
        , SUM(amount_usd)                               AS net_revenue_usd
        , bool_or(is_refund)                            AS has_refund
    FROM {{ ref('fct_payments') }}
    GROUP BY 1
),

final AS (
    SELECT
        s.subscription_id
        , s.user_id
        , s.plan 
        , s.trial_status
        , s.trial_started_at
        , s.converted_at
        , s.cancelled_at
        , s.trial_status = 'converted'                  AS is_converted
        , s.trial_status <> 'active'                    AS is_trial_finished
        , p.first_payment_at
        , p.plan_prise_usd
        , ROUND(p.plan_prise_usd / pl.months, 2)        AS monthly_values_usd
        , COALESCE(p.net_revenue_usd, 0)                AS net_revenue_usd
        , COALESCE(p.has_refund, false)                 AS has_refund
        , coalesce(u.is_test_account, false) AS is_test_account
    FROM subscriptions AS s 
    LEFT JOIN payments AS p ON p.subscription_id = s.subscription_id
    LEFT JOIN plans    AS pl ON pl.plan = s.plan
    LEFT JOIN users    AS u ON u.user_id = s.user_id
)

SELECT *
FROM final