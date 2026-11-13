-- Факт помилок застосунку: один рядок = одна помилка.
SELECT
      error_id
    , user_id
    , occurred_at
    , screen
    , error_code
FROM {{ ref('stg_app_errors') }}