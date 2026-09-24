WITH source AS(
    SELECT * FROM {{ source('bronze', 'nbu_rates') }}
),

renamed AS (
    SELECT
          to_date(exchangedate, 'DD.MM.YYYY') AS rate_date
        , cc                                  AS currency_code
        , rate_per_unit::numeric(12, 4)       AS uah_per_unit
        , to_date(calcdate, 'DD.MM.YYYY')     AS calculated_date
    FROM source
)

SELECT *
FROM renamed
