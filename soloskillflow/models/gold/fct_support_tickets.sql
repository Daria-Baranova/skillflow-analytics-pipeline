-- Факт звернень у підтримку: один рядок = одне звернення.
SELECT
      ticket_id
    , user_id
    , created_at
    , resolved_at
    , category
    , severity
FROM {{ ref('stg_support_tickets') }}