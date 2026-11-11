WITH payments AS (
    SELECT * FROM {{ ref('stg_payments') }}
),

rates AS (
    SELECT * FROM {{ ref('stg_nbu_rates') }}
),

users AS (
    SELECT user_id, is_test_account FROM {{ ref('dim_users') }}
),

converted AS (
    SELECT 
        p.payment_id
        , p.user_id
        , p.subscription_id
        , p.paid_at
        , p.paid_date
        , p.currency_code
        , p.amount
        , round(
            CASE p.currency_code
                WHEN 'USD' THEN p.amount
                WHEN 'UAH' THEN p.amount / usd.uah_per_unit
                WHEN 'EUR' THEN p.amount * eur.uah_per_unit / usd.uah_per_unit
            END
            , 2) AS amount_usd
        , p.status
        , p.is_refund
        , coalesce(u.is_test_account, false) AS is_test_account
    FROM payments AS p 
    LEFT JOIN rates AS usd 
        ON usd.rate_date = p.paid_date AND usd.currency_code = 'USD'
    LEFT JOIN rates AS eur 
        ON eur.rate_date = p.paid_date AND eur.currency_code = 'EUR'
    LEFT JOIN users AS u
        ON u.user_id = p.user_id
        -- у виручку йдуть лише завершені операції: оплата або повернення
    WHERE p.status IN ('succeeded', 'refunded')
)

SELECT *
FROM converted