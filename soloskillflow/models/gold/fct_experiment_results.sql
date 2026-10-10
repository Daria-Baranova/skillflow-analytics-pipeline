WITH experiment AS (
    SELECT * FROM {{ ref('fct_experiment') }}
),

long AS (
    SELECT 
        experiment_group
        , 'trial'       AS metric
        , 'primary'     AS metric_type
        , true          AS higher_is_better
        , is_trial::INT AS v 
    FROM experiment

    UNION ALL

    SELECT
        experiment_group
        , 'paid'
        , 'secondary'
        , true
        , is_paid::INT 
    FROM experiment

    UNION ALL

    SELECT
        experiment_group
        , 'activation'
        , 'secondary'
        , true
        , is_activated::INT
    FROM experiment

    UNION ALL 

    SELECT
        experiment_group
        , 'd1_return'
        , 'secondary'
        , true
        , is_returned_d1::INT
    FROM experiment

    UNION ALL

    SELECT
        experiment_group
        , 'onboarding_completed'
        , 'guardrail'
        , true
        , is_onboarding_completed::INT
    FROM experiment

    UNION ALL

    SELECT
        experiment_group
        , 'app_error'
        , 'guardrail'
        , false
        , had_app_error::INT
    FROM experiment

    UNION ALL 

    SELECT
        experiment_group
        , 'support_ticket'
        , 'guardrail'
        , false
        , had_support_ticket::INT 
    FROM experiment
),

g AS (
    SELECT
        metric
        , metric_type
        , higher_is_better
        , COUNT(*) FILTER (WHERE experiment_group = 'A')    AS n_a
        , COUNT(*) FILTER (WHERE experiment_group = 'B')    AS n_b
        , AVG(v)   FILTER (WHERE experiment_group = 'A')    AS p_a
        , AVG(v)   FILTER (WHERE experiment_group = 'B')    AS p_b
    FROM long
    GROUP BY 1, 2, 3
),

calc AS (
    SELECT
        *
        , 1.96 * sqrt(p_a * (1 - p_a) / n_a + p_b * (1- p_b) / n_b) AS margin
    FROM g 
),

final AS (
    SELECT 
        metric
        , metric_type
        , n_a
        , n_b
        , ROUND(100 * p_a, 2)                  AS a_pct
        , ROUND(100 * p_b, 2)                  AS b_pct
        , ROUND(100 * (p_b - p_a) / p_a, 1)    AS lift_pct
        , ROUND(100 * (p_b - p_a - margin), 2) AS ci_low_pp
        , ROUND(100 * (p_b - p_a + margin), 2) AS ci_high_pp
        , CASE
                WHEN p_b - p_a - margin <= 0 
                    AND  p_b - p_a + margin >= 0
                    THEN 'no difference'
                WHEN (p_b > p_a) = higher_is_better
                    THEN 'better'
                ELSE 'worse'
          END AS result
        , CASE
              WHEN p_b - p_a - margin <= 0 AND p_b - p_a + margin >= 0 THEN '⚪ no difference'
              WHEN (p_b > p_a) = higher_is_better THEN '🟢 better'
              ELSE '🔴 worse'
          END AS result_label
        , CASE metric_type
              WHEN 'primary'   THEN 1
              WHEN 'secondary' THEN 2
              WHEN 'guardrail' THEN 3
          END AS metric_order
    FROM calc
)

SELECT *
FROM final