-- Вітрина для дашборда: один рядок = один РЕАЛЬНИЙ користувач.
-- Тестові акаунти виключаються тут (єдине місце в проєкті).
WITH users AS (
    SELECT * FROM {{ ref('dim_users') }}
    WHERE {{ is_real_user('user_id') }}
),

countries AS (
    SELECT * FROM {{ ref('dim_countries') }}
),

channels AS (
    SELECT * FROM {{ ref('dim_channels') }}
),

-- група в основному експерименті; конфліктні призначення → NULL
experiment AS (
    SELECT user_id, experiment_group
    FROM {{ ref('dim_experiment_assignments') }}
    WHERE experiment_id = '{{ var("main_experiment_id") }}'
      AND has_conflicting_groups IS NOT TRUE
),

first_steps AS (
    SELECT * FROM {{ ref('int_user_first_steps') }}
),

-- гроші по користувачу (повернення вже від'ємні)
revenue AS (
    SELECT
          user_id
        , sum(amount_usd)                         AS net_revenue_usd
        , count(*) FILTER (WHERE NOT is_refund)   AS payments_count
    FROM {{ ref('fct_payments') }}
    GROUP BY 1
),

final AS (
    SELECT
          u.user_id
        -- хто це
        , u.signup_at
        , u.signup_date
        , u.signup_week
        , u.country
        , co.country_code
        , u.device
        , u.traffic_source
        , ch.is_paid                                       AS is_paid_channel
        , u.learning_goal
        , u.age_band
        , e.experiment_group
        -- воронка
        , f.onboarding_started_at
        , f.onboarding_completed_at
        , f.paywall_viewed_at
        , f.trial_activated_at
        , f.lesson_started_at
        , f.lesson_completed_at
        , f.lesson_completed_at IS NOT NULL                AS is_activated
        , coalesce(f.lesson_completed_at < u.signup_at, false) AS has_invalid_ttfv
        , CASE
              WHEN f.lesson_completed_at >= u.signup_at
              THEN round(extract(EPOCH FROM f.lesson_completed_at - u.signup_at) / 3600, 1)
          END                                              AS hours_to_first_value
        -- гроші
        , coalesce(r.net_revenue_usd, 0)                   AS net_revenue_usd
        , coalesce(r.payments_count, 0)                    AS payments_count
        , r.user_id IS NOT NULL                            AS is_paying
    FROM users AS u
    LEFT JOIN countries   AS co ON co.country = u.country
    LEFT JOIN channels    AS ch ON ch.channel = u.traffic_source
    LEFT JOIN experiment  AS e  ON e.user_id  = u.user_id
    LEFT JOIN first_steps AS f  ON f.user_id  = u.user_id
    LEFT JOIN revenue     AS r  ON r.user_id  = u.user_id
)

SELECT *
FROM final