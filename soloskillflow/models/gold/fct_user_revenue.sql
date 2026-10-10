WITH users AS (
    SELECT * FROM {{ ref('dim_users') }}
),

revenue AS (
    SELECT
          user_id
        , SUM(amount_usd)                         AS net_revenue_usd
        , COUNT(*) FILTER (WHERE NOT is_refund)   AS payments_count
    FROM {{ ref('fct_payments') }}
    GROUP BY 1
),

final AS (
    SELECT
          u.user_id
        , u.signup_week
        , u.traffic_source
        , u.country
        , u.experiment_group
        , u.is_test_account
        , coalesce(r.net_revenue_usd, 0)  AS net_revenue_usd
        , coalesce(r.payments_count, 0)   AS payments_count
        , r.user_id IS NOT NULL           AS is_paying
    FROM users AS u
    LEFT JOIN revenue AS r
        ON r.user_id = u.user_id
)

SELECT *
FROM final