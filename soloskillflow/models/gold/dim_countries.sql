-- Вимір країн: один рядок = одна країна; ISO-код беремо з дволітерного аліаса
SELECT
      country
    , max(upper(alias)) FILTER (WHERE length(alias) = 2) AS country_code
FROM {{ ref('country_aliases') }}
GROUP BY 1