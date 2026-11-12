-- Календарний вимір: один рядок = один день
WITH spine AS (
    {{ dbt_utils.date_spine(
        datepart   = "day",
        start_date = "cast('" ~ var('dim_date_start') ~ "' as date)",
        end_date   = "cast('" ~ var('dim_date_end') ~ "' as date)"
    ) }}
),

final AS (
    SELECT
          date_day::DATE                              AS date_day
        , date_trunc('week',  date_day)::DATE         AS week_start     -- понеділок
        , date_trunc('month', date_day)::DATE         AS month_start
        , extract(ISODOW FROM date_day)::INT          AS day_of_week    -- 1 = пн … 7 = нд
        , to_char(date_day, 'Dy')                     AS day_name
        , extract(ISODOW FROM date_day) IN (6, 7)     AS is_weekend
        , extract(WEEK  FROM date_day)::INT           AS iso_week
        , to_char(date_day, 'Mon YYYY')               AS month_name
    FROM spine
)

SELECT *
FROM final