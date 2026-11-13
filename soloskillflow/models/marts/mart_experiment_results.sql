-- Підсумок A/B-тесту: один рядок = одна метрика.
-- Lift B проти A, довірчий інтервал і висновок better / worse / no difference.
WITH experiment AS (
    SELECT * FROM {{ ref('mart_experiment_users') }}
),

-- unpivot: кожен учасник × 7 метрик (замість 7 блоків UNION ALL)
long AS (
    SELECT
          e.experiment_group
        , m.metric
        , m.metric_type
        , m.higher_is_better
        , m.v
    FROM experiment AS e
    CROSS JOIN LATERAL (
        VALUES
              ('trial',                'primary',   true,  e.is_trial::INT)
            , ('paid',                 'secondary', true,  e.is_paid::INT)
            , ('activation',           'secondary', true,  e.is_activated::INT)
            , ('d1_return',            'secondary', true,  e.is_returned_d1::INT)
            , ('onboarding_completed', 'guardrail', true,  e.is_onboarding_completed::INT)
            , ('app_error',            'guardrail', false, e.had_app_error::INT)
            , ('support_ticket',       'guardrail', false, e.had_support_ticket::INT)
    ) AS m (metric, metric_type, higher_is_better, v)
),

groups AS (
    SELECT
          metric
        , metric_type
        , higher_is_better
        , count(*) FILTER (WHERE experiment_group = 'A') AS n_a
        , count(*) FILTER (WHERE experiment_group = 'B') AS n_b
        , avg(v)   FILTER (WHERE experiment_group = 'A') AS p_a
        , avg(v)   FILTER (WHERE experiment_group = 'B') AS p_b
    FROM long
    GROUP BY 1, 2, 3
),

-- z: primary без поправки, решта — з поправкою Бонферроні
z_values AS (
    SELECT
          *
        , CASE
              WHEN metric_type = 'primary' THEN {{ var('ab_z_primary') }}
              ELSE {{ var('ab_z_corrected') }}
          END AS z
    FROM groups
),

calc AS (
    SELECT
          *
        , z * sqrt(p_a * (1 - p_a) / n_a + p_b * (1 - p_b) / n_b) AS margin
    FROM z_values
),

-- висновок рахуємо ОДИН раз
verdict AS (
    SELECT
          *
        , CASE
              WHEN p_b - p_a - margin <= 0
               AND p_b - p_a + margin >= 0       THEN 'no difference'
              WHEN (p_b > p_a) = higher_is_better THEN 'better'
              ELSE 'worse'
          END AS result
    FROM calc
),

final AS (
    SELECT
          metric
        , metric_type
        , CASE metric_type
              WHEN 'primary'   THEN 1
              WHEN 'secondary' THEN 2
              ELSE 3
          END                                              AS metric_order
        , n_a
        , n_b
        , z
        , round(100 * p_a, 2)                              AS a_pct
        , round(100 * p_b, 2)                              AS b_pct
        , round(100 * (p_b - p_a) / NULLIF(p_a, 0), 1)     AS lift_pct
        , round(100 * (p_b - p_a - margin), 2)             AS ci_low_pp
        , round(100 * (p_b - p_a + margin), 2)             AS ci_high_pp
        , result
        -- підпис для дашборда будуємо з result, а не повторюємо умову
        , CASE result
              WHEN 'better' THEN '🟢 better'
              WHEN 'worse'  THEN '🔴 worse'
              ELSE '⚪ no difference'
          END                                              AS result_label
    FROM verdict
)

SELECT *
FROM final