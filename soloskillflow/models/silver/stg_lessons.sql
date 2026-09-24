WITH source AS (
    SELECT * FROM {{ source('bronze', 'lessons') }}
),

cleaned AS (
    SELECT
          lesson_id
        , title
        , topic
        , level
        -- "20 min" → 20, тип: ціле число
        , replace(duration_min, ' min', '')::INT AS duration_min
        -- yes / true / TRUE / 1 → true, решта → false
        , lower(is_active) IN ('yes', 'true', '1') AS is_active
    FROM source
)

SELECT *
FROM cleaned