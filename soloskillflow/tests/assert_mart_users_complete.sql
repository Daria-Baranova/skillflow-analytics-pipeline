-- Повнота вітрини: у mart_users має бути кожен реальний користувач.
-- Рахуємо НЕЗАЛЕЖНО від макросу is_real_user, щоб тест ловив помилки в ньому.
WITH expected AS (
    SELECT count(*) AS n
    FROM {{ ref('dim_users') }}
    WHERE is_test_account IS NOT TRUE
),

actual AS (
    SELECT count(*) AS n
    FROM {{ ref('mart_users') }}
)

SELECT e.n AS expected_users, a.n AS actual_users
FROM expected AS e
CROSS JOIN actual AS a
WHERE e.n <> a.n