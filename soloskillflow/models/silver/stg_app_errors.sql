WITH source AS (
    SELECT * FROM {{ source('bronze', 'app_errors') }}
),

cleaned AS (
    SELECT 
          error_id
        , user_id
        , occurred_at
        , screen
        , upper(trim(error_code)) AS error_code
        , message
    FROM source
)

SELECT *
FROM cleaned

