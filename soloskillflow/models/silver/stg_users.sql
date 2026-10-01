WITH source AS (
    SELECT *
    FROM {{ source('bronze', 'users') }}
),

deduplicate AS (
    SELECT
          *
        , row_number() OVER (PARTITION BY user_id ORDER BY signup_at) AS rn 
    FROM source
),

cleaned AS (
    SELECT
      user_id
    , coalesce(
          signup_at
        , to_timestamp(signup_at__v_text || ' +00', 'DD/MM/YYYY HH24:MI TZH')
      ) AS signup_at
    , CASE upper(trim(country))
        WHEN 'UA' THEN 'Ukraine'
        WHEN 'PL' THEN 'Poland'
        WHEN 'DE' THEN 'Germany'
        WHEN 'US' THEN 'United States'
        WHEN 'ES' THEN 'Spain'
        WHEN 'CZ' THEN 'Czechia'
        WHEN 'CA' THEN 'Canada'
        ELSE initcap(trim(country))
      END AS country
    , trim(device)          AS device
    , trim(traffic_source)  AS traffic_source
    , learning_goal
    , age_band
    , is_test_account = 1 AS is_test_account
FROM deduplicate
WHERE rn = 1
)

SELECT *
FROM cleaned