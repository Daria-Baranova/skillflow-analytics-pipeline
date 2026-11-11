WITH source AS (
    SELECT * FROM {{ source('bronze', 'payments') }}
),

deduplicated AS (
    SELECT 
          *
        , row_number() OVER (PARTITION BY payment_id ORDER BY paid_at) AS rn 
    FROM source
),

cleaned AS (
    SELECT 
          payment_id
        , user_id
        , subscription_id
        , paid_at
        , {{ to_local_date('paid_at') }} AS paid_date
        , currency      AS currency_code
        , replace(
            regexp_replace(amount_raw, '[^0-9,.-]', '', 'g'), 
            ',', '.'
        )::NUMERIC(12, 2) AS amount
        , lower(trim(status)) AS status
        , is_refund = 1 AS is_refund
    FROM deduplicated
    WHERE rn = 1
)

SELECT *
FROM cleaned