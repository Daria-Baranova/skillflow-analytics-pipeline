-- Вітрина платежів: один рядок = один платіж реального користувача (USD за курсом НБУ).
WITH payments AS (
    SELECT * FROM {{ ref('fct_payments') }} AS p
    WHERE {{ is_real_user('p.user_id') }}
),

users AS (
    SELECT user_id, traffic_source, country, experiment_group
    FROM {{ ref('mart_users') }}
),

final AS (
    SELECT
          p.payment_id
        , p.user_id
        , p.subscription_id
        , p.paid_at
        , p.paid_date
        , p.currency_code
        , p.amount
        , p.amount_usd
        , p.status
        , p.is_refund
        , u.traffic_source
        , u.country
        , u.experiment_group
    FROM payments AS p
    LEFT JOIN users AS u ON u.user_id = p.user_id   -- LEFT: загублені платежі не зникають
)

SELECT *
FROM final