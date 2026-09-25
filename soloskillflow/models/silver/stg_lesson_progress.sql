WITH source AS (
    SELECT * FROM {{ source('bronze', 'lesson_progress') }}
),

cleaned AS (
    SELECT
          progress_id
        , user_id
        , lesson_id
        , started_at
        , CASE
            WHEN completed_at < started_at THEN NULL
            ELSE completed_at
          END AS completed_at
        , least(replace(completion_pct, '%', '')::INT, 100) AS completion_pct
    FROM source
)

SELECT *
FROM cleaned