WITH spend AS (
    SELECT * FROM {{ ref('stg_marketing_spend') }}
),

users AS (
    SELECT * FROM {{ ref('dim_users') }}
    WHERE is_test_account IS NOT TRUE
),

paying AS (
    SELECT DISTINCT user_id 
    FROM {{ ref('fct_subscriptions') }}
    WHERE is_converted
),

signups AS (
    SELECT
        u.signup_date
        , u.traffic_source              AS channel
        , u.country
        , COUNT(*)                      AS signups
        , COUNT(p.user_id)              AS paying_users
    FROM users AS u 
    LEFT JOIN paying AS p 
        ON p.user_id = u.user_id
    GROUP BY 1, 2, 3
),

final AS (
    SELECT
        s.spend_date
        , s.channel
        , s.country
        , s.spend_usd
        , s.impressions
        , s.clicks
        , COALESCE(g.signups, 0)        AS signups
        , COALESCE(g.paying_users, 0)   AS paying_users
    FROM spend AS s 
    LEFT JOIN signups AS g 
        ON  g.signup_date   = s.spend_date
        AND g.channel       = s.channel
        AND g.country       = s.country
)

SELECT *
FROM final
