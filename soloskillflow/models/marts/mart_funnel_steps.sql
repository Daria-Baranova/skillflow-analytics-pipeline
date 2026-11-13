-- Сувора воронка для дашборда: один рядок = користувач × пройдений крок.
-- Крок зараховано, якщо пройдені всі попередні і в правильному порядку (з допуском).
WITH users AS (
    SELECT * FROM {{ ref('mart_users') }}
),

-- "широкий" формат → "довгий": користувач + крок + час кроку
long AS (
    SELECT user_id, 1 AS step_order, '1. Signup' AS step_name, signup_at AS step_at FROM users
    UNION ALL SELECT user_id, 2, '2. Onboarding started',   onboarding_started_at   FROM users
    UNION ALL SELECT user_id, 3, '3. Onboarding completed', onboarding_completed_at FROM users
    UNION ALL SELECT user_id, 4, '4. Paywall viewed',       paywall_viewed_at       FROM users
    UNION ALL SELECT user_id, 5, '5. Trial activated',      trial_activated_at      FROM users
    UNION ALL SELECT user_id, 6, '6. Lesson started',       lesson_started_at       FROM users
    UNION ALL SELECT user_id, 7, '7. Lesson completed',     lesson_completed_at     FROM users
),

ordered AS (
    SELECT
          *
        , lag(step_at) OVER (PARTITION BY user_id ORDER BY step_order) AS prev_step_at
    FROM long
),

checked AS (
    SELECT
          *
        , CASE
              WHEN step_at IS NULL THEN false
              WHEN step_order = 1  THEN true
              ELSE coalesce(
                       step_at >= prev_step_at - INTERVAL '{{ var("event_time_tolerance_hours") }} hours'
                     , false)
          END AS reached_in_order
    FROM ordered
),

strict AS (
    SELECT
          *
        , bool_and(reached_in_order) OVER (PARTITION BY user_id ORDER BY step_order) AS reached_strict
    FROM checked
),

final AS (
    SELECT
          s.user_id
        , s.step_order
        , s.step_name
        , u.signup_week
        , u.traffic_source
        , u.experiment_group
        , u.country
        , u.device
    FROM strict AS s
    INNER JOIN users AS u
        ON u.user_id = s.user_id
    WHERE s.reached_strict
)

SELECT *
FROM final