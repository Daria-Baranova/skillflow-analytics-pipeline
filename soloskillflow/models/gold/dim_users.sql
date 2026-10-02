WITH users AS (
    SELECT * FROM {{ ref('stg_users') }}
),

experiments AS (
    SELECT * FROM {{ ref('stg_experiments') }}
),

final AS (
    SELECT 
        u.user_id
        , u.signup_at
        , u.signup_at::DATE                         AS signup_date
        , date_trunc('week', u.signup_at)::DATE     AS signup_week
        , u.country
        , u.device
        , u.traffic_source
        , u.learning_goal
        , u.age_band
        , e.experiment_group
        , u.is_test_account
    FROM users AS u 
    LEFT JOIN experiments AS e 
        ON e.user_id = u.user_id
)

SELECT *
FROM final