-- Вимір користувачів: один рядок = один користувач з атрибутами.
-- Групи експериментів живуть у bridge dim_experiment_assignments (щоб не було fan-out).
WITH users AS (
    SELECT * FROM {{ ref('stg_users') }}
),

final AS (
    SELECT
          u.user_id
        , u.signup_at
        , {{ to_local_date('u.signup_at') }}        AS signup_date
        , {{ to_local_week('u.signup_at') }}        AS signup_week
        , u.country
        , u.device
        , u.traffic_source
        , u.learning_goal
        , u.age_band
        , u.is_test_account
    FROM users AS u
)

SELECT *
FROM final