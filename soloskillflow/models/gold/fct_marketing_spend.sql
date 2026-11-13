-- Факт маркетингових витрат: один рядок = день × канал × країна.
-- Тільки ключі й міри; атрибути каналів і країн живуть у вимірах.
SELECT
      spend_date
    , channel
    , country
    , spend_usd
    , impressions
    , clicks
    , is_negative_spend
FROM {{ ref('stg_marketing_spend') }}