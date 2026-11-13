-- Вітрина залучення: один рядок = день × канал × країна.
-- Повна сітка (spine): не губиться жодна реєстрація —
-- ні з країн без даних про витрати, ні без країни.
WITH spend AS (
    SELECT * FROM {{ ref('fct_marketing_spend') }}
),

signups AS (
    SELECT
          signup_date                           AS report_date
        , traffic_source                        AS channel
        , coalesce(country, 'Unknown')          AS country
        , count(*)                              AS signups
        , count(*) FILTER (WHERE is_paying)     AS paying_users
    FROM {{ ref('mart_users') }}
    GROUP BY 1, 2, 3
),

-- межі: від першого до останнього дня, де є витрати або реєстрації
bounds AS (
    SELECT min(report_date) AS start_date, max(report_date) AS end_date
    FROM (
        SELECT spend_date AS report_date FROM spend
        UNION ALL
        SELECT report_date FROM signups
    ) AS all_dates
),

dates AS (
    SELECT d.date_day AS report_date
    FROM {{ ref('dim_date') }} AS d
    CROSS JOIN bounds AS b
    WHERE d.date_day BETWEEN b.start_date AND b.end_date
),

-- "Unknown" як окремий рядок сітки для користувачів без країни
countries AS (
    SELECT country, country_code FROM {{ ref('dim_countries') }}
    UNION ALL
    SELECT 'Unknown', NULL
),

spine AS (
    SELECT
          d.report_date
        , ch.channel
        , ch.channel_order
        , ch.is_paid
        , co.country
        , co.country_code
    FROM dates AS d
    CROSS JOIN {{ ref('dim_channels') }} AS ch
    CROSS JOIN countries AS co
),

final AS (
    SELECT
          s.report_date
        , s.channel
        , s.channel_order
        , s.is_paid                                   AS is_paid_channel
        , s.country
        , s.country_code
        -- витрати: NULL = невідомо (не нуль!)
        , sp.spend_usd IS NOT NULL                    AS has_spend_data
        , sp.spend_usd
        , sp.impressions
        , sp.clicks
        -- усі реєстрації
        , coalesce(g.signups, 0)                      AS signups
        , coalesce(g.paying_users, 0)                 AS paying_users
        -- адитивні частини для CAC: лише там, де витрати відомі
        , CASE WHEN sp.spend_usd IS NOT NULL THEN coalesce(g.signups, 0) ELSE 0 END      AS signups_with_spend
        , CASE WHEN sp.spend_usd IS NOT NULL THEN coalesce(g.paying_users, 0) ELSE 0 END AS paying_users_with_spend
    FROM spine AS s
    LEFT JOIN spend AS sp
        ON  sp.spend_date = s.report_date
        AND sp.channel    = s.channel
        AND sp.country    = s.country
    LEFT JOIN signups AS g
        ON  g.report_date = s.report_date
        AND g.channel     = s.channel
        AND g.country     = s.country
)

SELECT *
FROM final