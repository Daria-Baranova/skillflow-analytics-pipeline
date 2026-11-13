{# Єдине правило проєкту: "реальний користувач" = НЕ позначений як тестовий.
   Користувачі, яких немає в довіднику (загублені платежі), НЕ відкидаються.
   Підзапит віддає колонку test_user_id, а не user_id: тому user_id
   завжди береться із зовнішньої таблиці, навіть без аліаса. #}
{% macro is_real_user(user_id_column) -%}
    NOT EXISTS (
        SELECT 1
        FROM (
            SELECT user_id AS test_user_id
            FROM {{ ref('dim_users') }}
            WHERE is_test_account
        ) AS test_users
        WHERE test_users.test_user_id = {{ user_id_column }}
    )
{%- endmacro %}