WITH source AS (
    SELECT *
    FROM {{ source('bronze', 'users') }}
),

country_aliases AS (
    SELECT * FROM {{ ref('country_aliases') }}
),

channel_aliases AS (
    SELECT * FROM {{ ref('channel_aliases') }}
),

-- у bronze signup_at — сирий текст у трьох форматах, і всі три — час в UTC
parsed AS (
    SELECT
          *
        , CASE
              -- 24/06/2026 10:55
              WHEN signup_at LIKE '__/__/____%'
                  THEN to_timestamp(signup_at || ' +00', 'DD/MM/YYYY HH24:MI TZH')
              -- 2026-06-06 14:28:39 і 2026-06-03T17:30:52Z:
              -- прибираємо Z і явно дописуємо +00, інакше Postgres візьме пояс сесії (Київ)
              ELSE (rtrim(signup_at, 'Z') || '+00')::timestamptz
          END AS signup_at_utc
    FROM source
),

deduplicate AS (
    SELECT
          *
        , row_number() OVER (PARTITION BY user_id ORDER BY signup_at_utc) AS rn
    FROM parsed
),

cleaned AS (
    SELECT
      d.user_id
    , d.signup_at_utc AS signup_at
    , ca.country
    -- хендлер: країна вказана, але її написання невідоме довіднику
    , (d.country IS NOT NULL AND ca.country IS NULL) AS is_unknown_country
    , trim(d.device)          AS device
    , ch.channel AS traffic_source
    , (d.traffic_source IS NOT NULL AND ch.channel IS NULL) AS is_unknown_channel
    , d.learning_goal
    , d.age_band
    , coalesce(d.is_test_account = 1, false) AS is_test_account
FROM deduplicate AS d
LEFT JOIN country_aliases AS ca
    ON ca.alias = {{ alias_key('d.country') }}
LEFT JOIN channel_aliases AS ch
    ON ch.alias = {{ alias_key('d.traffic_source') }}
WHERE d.rn = 1
)

SELECT *
FROM cleaned
