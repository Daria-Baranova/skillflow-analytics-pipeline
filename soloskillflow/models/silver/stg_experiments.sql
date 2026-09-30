WITH source AS (
    SELECT * FROM {{ source('bronze', 'experiments') }}
),

deduplicated AS ( 
    SELECT 
        *
        , row_number() OVER (
            PARTITION BY experiment_id, user_id
            ORDER BY 
                CASE WHEN assignment_source = 'sdk' THEN 0 ELSE 1 END 
                , assigned_at
        ) AS rn 
    FROM source 
),

cleaned AS (
    SELECT
            experiment_id
            , user_id 
            , CASE upper(trim(experiment_group))
                    WHEN 'CONTROL'      THEN 'A'
                    WHEN 'TREATMENT'    THEN 'B'
                    ELSE upper(trim(experiment_group))
                END AS experiment_group
            , assigned_at
            , assignment_source
    FROM deduplicated
    WHERE rn = 1
)

SELECT *
FROM cleaned