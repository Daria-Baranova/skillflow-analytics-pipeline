-- Вимір каналів залучення: один рядок = один канал
SELECT
      channel
    , channel_order
    , is_paid
FROM {{ ref('channels') }}