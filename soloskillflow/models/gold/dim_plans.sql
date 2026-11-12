-- Вимір планів підписки: один рядок = один план
WITH plans AS (
    SELECT * FROM {{ ref('plans') }}
)

SELECT
      plan
    , plan_order
    , months
    , coverage_days
FROM plans