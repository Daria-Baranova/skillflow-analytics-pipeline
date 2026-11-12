WITH payments AS (
    SELECT
        p.subscription_id
        , p.paid_date
        , p.is_refund
        , p.amount_usd
        , p.is_test_account
        , s.plan
        , pl.months
        , pl.coverage_days
    FROM {{ ref('fct_payments') }} AS p 
    INNER JOIN {{ ref('fct_subscriptions') }} AS s 
        ON s.subscription_id = p.subscription_id
    INNER JOIN {{ ref('dim_plans') }} AS pl
        ON pl.plan = s.plan
),

refunds AS (
    SELECT 
        subscription_id
        , MIN(paid_date) AS refund_date
    FROM payments
    WHERE is_refund
    GROUP BY 1
),

coverage AS (
    SELECT 
        p.subscription_id
        , p.plan
        , p.paid_date AS start_date
        , p.paid_date + p.coverage_days AS end_date
        , r.refund_date
        , p.amount_usd / p.months AS monthly_value_usd
    FROM payments AS p 
    LEFT JOIN refunds AS r 
        ON r.subscription_id = p.subscription_id
    WHERE NOT p.is_refund
      AND p.is_test_account IS NOT TRUE
),

days AS (
    SELECT generate_series(
                (SELECT MIN(start_date) FROM coverage)
                , (SELECT MAX(paid_date) FROM payments WHERE NOT is_refund)
                , INTERVAL '1 day'
            )::DATE AS mrr_date
),

active AS (
    SELECT
        d.mrr_date
        , c.plan
        , c.subscription_id
        , MAX(c.monthly_value_usd) AS monthly_value_usd
    FROM days AS d 
    INNER JOIN coverage AS c 
        ON c.start_date <= d.mrr_date
        AND d.mrr_date < c.end_date
        AND (c.refund_date IS NULL 
             OR d.mrr_date < c.refund_date)
    GROUP BY 1, 2, 3
)

SELECT 
    mrr_date
    , plan
    , COUNT(*)                          AS active_subscriptions
    , ROUND(SUM(monthly_value_usd), 2)  AS mrr_usd
FROM active 
GROUP BY 1, 2