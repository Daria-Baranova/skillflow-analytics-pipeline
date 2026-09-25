WITH source AS (
    SELECT * FROM {{ source('bronze', 'marketing_spend') }}
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
          spend_date::DATE AS spend_date
        , CASE lower(replace(replace(channel, ' ', ''), '_', ''))
                WHEN 'organic'      THEN 'Organic'
                WHEN 'paidsocial'   THEN 'Paid Social'
                WHEN 'googleads'    THEN 'Google Ads'
                WHEN 'referral'     THEN 'Referral'
                WHEN 'email'        THEN 'Email'
          END AS channel
        , country
        , CASE
            WHEN spend_usd_num < 0 THEN NULL
            ELSE spend_usd_num
          END AS spend_usd
        , impressions
        , clicks
    FROM parsed
)

SELECT *
FROM cleaned