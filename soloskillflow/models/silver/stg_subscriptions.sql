WITH source AS (
    SELECT * FROM {{ source('bronze', 'subscriptions')}}
),

deduplicate AS (
    SELECT
          *
        , row_number() OVER (PARTITION BY subscription_id ORDER BY trial_started_at) AS rn
    FROM source
),

cleaned AS (
    SELECT
          subscription_id
        , user_id
        , trial_type
        , plan 
        , CASE lower(trim(trial_status))
            WHEN 'conv'     THEN 'converted'
            WHEN 'canceled' THEN 'cancelled'
            ELSE lower(trim(trial_status))
          END AS trial_status
        , trial_started_at
        , converted_at
        , cancelled_at
    FROM deduplicate
    WHERE rn = 1
)

SELECT *
FROM cleaned