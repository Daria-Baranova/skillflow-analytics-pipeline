WITH source AS (
    SELECT * FROM {{ source('bronze', 'events') }}
),

deduplicated AS (
    SELECT 
        *
        , row_number() OVER (
            PARTITION BY event_id
            ORDER BY
                CASE WHEN user_id IS NULL THEN 1 ELSE 0 END
                , event_ts DESC
            ) AS rn 
        FROM source
),

cleaned AS (
    SELECT 
        event_id
        , coalesce(
                user_id
                , substring(split_part(session_id, '-', 1) FROM 2)::BIGINT
        ) AS user_id
        , session_id
        , lower(trim(event_name))   AS event_name
        , event_ts
        , lower(trim(platform))     AS platform
        , properties__source        AS signup_source
        , properties__lesson_id     AS lesson_id 
        , properties__step          AS onboarding_step
        , properties__trial_type    AS trial_type 
    FROM deduplicated
    WHERE rn = 1
)

SELECT *
FROM cleaned