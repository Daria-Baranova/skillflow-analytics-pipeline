-- Призначення в експерименти: один рядок = користувач × експеримент (bridge)
SELECT
      experiment_id
    , user_id
    , experiment_group
    , assigned_at
    , assignment_source
    , has_conflicting_groups
FROM {{ ref('stg_experiments') }}