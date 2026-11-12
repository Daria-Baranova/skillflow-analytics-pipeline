WITH source AS (
    SELECT *
    FROM {{ source('bronze', 'users') }}
),

country_aliases AS (
    SELECT * FROM {{ ref('country_aliases') }}
),

deduplicate AS (
    SELECT
          *
        , row_number() OVER (PARTITION BY user_id ORDER BY signup_at) AS rn 
    FROM source
),

cleaned AS (
    SELECT
      d.user_id
    , coalesce(
          d.signup_at
        , to_timestamp(d.signup_at__v_text || ' +00', 'DD/MM/YYYY HH24:MI TZH')
      ) AS signup_at
    , ca.country
    -- хендлер: країна вказана, але її написання невідоме довіднику
    , (d.country IS NOT NULL AND ca.country IS NULL) AS is_unknown_country
    , trim(d.device)          AS device
    , trim(d.traffic_source)  AS traffic_source
    , d.learning_goal
    , d.age_band
    , coalesce(d.is_test_account = 1, false) AS is_test_account
FROM deduplicate AS d
LEFT JOIN country_aliases AS ca
    ON ca.alias = lower(trim(d.country))
WHERE d.rn = 1
)

SELECT *
FROM cleaned