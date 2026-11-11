-- Правило: повернення = статус 'refunded' = від'ємна сума.
-- Тест повертає рядки, що порушують правило. 0 рядків = тест пройдено.
SELECT
      payment_id
    , status
    , is_refund
    , amount
FROM {{ ref('stg_payments') }}
WHERE (status = 'refunded') <> is_refund
   OR (amount < 0) <> is_refund