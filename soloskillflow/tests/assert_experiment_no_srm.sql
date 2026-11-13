-- SRM: чи розміри груп відрізняються від запланованих 50/50 більше, ніж дозволяє випадковість.
-- Хі-квадрат з 1 ступенем свободи; поріг 10.83 = p 0.001 (стандарт для SRM).
-- Тест повертає рядок (= падає), якщо розподіл груп підозрілий.
WITH groups AS (
    SELECT
          count(*) FILTER (WHERE experiment_group = 'A') AS n_a
        , count(*) FILTER (WHERE experiment_group = 'B') AS n_b
    FROM {{ ref('mart_experiment_users') }}
),

chi AS (
    SELECT
          n_a
        , n_b
        , power(n_a - (n_a + n_b) / 2.0, 2) / ((n_a + n_b) / 2.0)
        + power(n_b - (n_a + n_b) / 2.0, 2) / ((n_a + n_b) / 2.0) AS chi_square
    FROM groups
)

SELECT *
FROM chi
WHERE chi_square > 10.83