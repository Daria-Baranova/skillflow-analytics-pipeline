-- MRR по днях і планах: один рядок = день × план.
-- Кожен успішний платіж покриває coverage_days днів; повернення коштів завершує покриття.
WITH payments AS (
    SELECT
          p.subscription_id
        , p.paid_date
        , p.is_refund
        , p.amount_usd
        , s.plan
        , pl.plan_order
        , pl.months
        , pl.coverage_days
    FROM {{ ref('mart_payments') }} AS p
    INNER JOIN {{ ref('mart_subscriptions') }} AS s ON s.subscription_id = p.subscription_id
    INNER JOIN {{ ref('dim_plans') }}          AS pl ON pl.plan = s.plan
),

refunds AS (
    SELECT subscription_id, min(paid_date) AS refund_date
    FROM payments
    WHERE is_refund
    GROUP BY 1
),

coverage AS (
    SELECT
          p.subscription_id
        , p.plan
        , p.plan_order
        , p.paid_date                        AS start_date
        , p.paid_date + p.coverage_days      AS end_date
        , r.refund_date
        , p.amount_usd / p.months            AS monthly_value_usd
    FROM payments AS p
    LEFT JOIN refunds AS r ON r.subscription_id = p.subscription_id
    WHERE NOT p.is_refund
),

-- календар з виміру дат: від першого до останнього успішного платежу
days AS (
    SELECT date_day AS mrr_date
    FROM {{ ref('dim_date') }}
    WHERE date_day BETWEEN (SELECT min(start_date) FROM coverage)
                       AND (SELECT max(start_date) FROM coverage)
),

active AS (
    SELECT
          d.mrr_date
        , c.plan
        , c.plan_order
        , c.subscription_id
        , max(c.monthly_value_usd) AS monthly_value_usd
    FROM days AS d
    INNER JOIN coverage AS c
        ON  c.start_date <= d.mrr_date
        AND d.mrr_date < c.end_date
        AND (c.refund_date IS NULL OR d.mrr_date < c.refund_date)
    GROUP BY 1, 2, 3, 4
)

SELECT
      mrr_date
    , plan
    , plan_order
    , count(*)                          AS active_subscriptions
    , round(sum(monthly_value_usd), 2)  AS mrr_usd
FROM active
GROUP BY 1, 2, 3