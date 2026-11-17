-- Факт активності: один рядок = користувач × день, коли були події (день за reporting_tz).
-- Тільки ключі й міри. Правило "активність лише після реєстрації" живе у вітрині.
WITH events AS (
    SELECT * FROM {{ ref('stg_events') }}
),

daily AS (
    SELECT
          user_id
        , {{ to_local_date('event_ts') }}   AS activity_date
        , COUNT(*)                         AS events_count
        , COUNT(DISTINCT session_id)       AS sessions_count
    FROM events
    GROUP BY 1, 2
)

SELECT *
FROM daily