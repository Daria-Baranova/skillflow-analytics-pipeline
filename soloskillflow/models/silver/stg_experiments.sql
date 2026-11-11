WITH source AS (
    SELECT * FROM {{ source('bronze', 'experiments') }}
),

-- приводимо назви груп до A / B
normalized AS (
    SELECT
          *
        , CASE upper(trim(experiment_group))
              WHEN 'CONTROL'   THEN 'A'
              WHEN 'TREATMENT' THEN 'B'
              ELSE upper(trim(experiment_group))
          END AS group_clean
    FROM source
),

-- хендлер: користувач має більше однієї групи → призначення порушене
conflicts AS (
    SELECT
          experiment_id
        , user_id
        , count(DISTINCT group_clean) > 1 AS has_conflicting_groups
    FROM normalized
    GROUP BY 1, 2
),

deduplicated AS (
    SELECT
          *
        , row_number() OVER (
              PARTITION BY experiment_id, user_id
              ORDER BY
                  CASE WHEN assignment_source = 'sdk' THEN 0 ELSE 1 END
                , assigned_at
                , _dlt_id                      -- tie-breaker: результат завжди однаковий
          ) AS rn
    FROM normalized
),

cleaned AS (
    SELECT
          d.experiment_id
        , d.user_id
        , d.group_clean AS experiment_group
        , d.assigned_at
        , d.assignment_source
        , c.has_conflicting_groups
    FROM deduplicated AS d
    INNER JOIN conflicts AS c
        ON  c.experiment_id = d.experiment_id
        AND c.user_id       = d.user_id
    WHERE d.rn = 1
)

SELECT *
FROM cleaned