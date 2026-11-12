-- Перший раз, коли користувач зробив кожну дію в продукті (з подій).
-- Один рядок = один користувач. Використовується воронкою, TTFV і A/B-аналізом.
WITH events AS (
    SELECT * FROM {{ ref('stg_events') }}
)

SELECT
      user_id
    , min(event_ts) FILTER (WHERE event_name = 'signup')               AS signup_event_at   -- лише для довідки
    , min(event_ts) FILTER (WHERE event_name = 'onboarding_started')   AS onboarding_started_at
    , min(event_ts) FILTER (WHERE event_name = 'onboarding_completed') AS onboarding_completed_at
    , min(event_ts) FILTER (WHERE event_name = 'paywall_viewed')       AS paywall_viewed_at
    , min(event_ts) FILTER (WHERE event_name = 'trial_activated')      AS trial_activated_at
    , min(event_ts) FILTER (WHERE event_name = 'lesson_started')       AS lesson_started_at
    , min(event_ts) FILTER (WHERE event_name = 'lesson_completed')     AS lesson_completed_at
FROM events
GROUP BY 1