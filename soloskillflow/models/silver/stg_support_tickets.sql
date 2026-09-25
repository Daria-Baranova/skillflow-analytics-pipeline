 WITH source AS (
    SELECT * FROM {{ source('bronze', 'support_tickets') }}
),

cleaned AS (
    SELECT
          ticket_id
        , user_id
        , created_at
        , lower(trim(category)) AS category
        , severity
        , resolved_at
    FROM source
)

SELECT *
FROM cleaned