WITH source AS (
    SELECT * FROM {{ source('bronze', 'marketing_spend') }}
),

country_aliases AS (
    SELECT * FROM {{ ref('country_aliases') }}
),

channel_aliases AS (
    SELECT * FROM {{ ref('channel_aliases') }}
),

parsed AS (
    SELECT 
          *
        , replace(
                regexp_replace(spend_usd, '[^0-9,.-]', '', 'g'),
                ',', '.'
        )::NUMERIC(12,2) AS spend_usd_num
    FROM source
),

cleaned AS (
    SELECT
          p.spend_date::DATE AS spend_date
        , ch.channel
        , co.country
        -- хендлери: значення, яких немає в довідниках, і неможливі суми
        , (p.channel IS NOT NULL AND ch.channel IS NULL) AS is_unknown_channel
        , (p.country IS NOT NULL AND co.country IS NULL) AS is_unknown_country
        , coalesce(p.spend_usd_num < 0, false)           AS is_negative_spend
        , CASE
              WHEN p.spend_usd_num < 0 THEN NULL
              ELSE p.spend_usd_num
          END AS spend_usd
        , p.impressions
        , p.clicks
    FROM parsed AS p
    LEFT JOIN channel_aliases AS ch
        ON ch.alias = {{ alias_key('p.channel') }}
    LEFT JOIN country_aliases AS co
        ON co.alias = {{ alias_key('p.country') }}
)

SELECT *
FROM cleaned