-- Звірка: вітрина залучення не губить і не дублює ні реєстрацій, ні грошей.
WITH mart AS (
    SELECT
          sum(signups)   AS mart_signups
        , sum(spend_usd) AS mart_spend
    FROM {{ ref('mart_acquisition_daily') }}
),

expected AS (
    SELECT
          (SELECT count(*) FROM {{ ref('mart_users') }})               AS expected_signups
        , (SELECT sum(spend_usd) FROM {{ ref('fct_marketing_spend') }}) AS expected_spend
)

SELECT *
FROM mart
CROSS JOIN expected
WHERE mart_signups <> expected_signups
   OR mart_spend   <> expected_spend