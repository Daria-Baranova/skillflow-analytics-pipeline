{# Єдине правило проєкту: "реальний користувач" = НЕ позначений як тестовий.
   Користувачі, яких немає в довіднику (загублені платежі), НЕ відкидаються. #}
{% macro is_real_user(user_id_column) -%}
    NOT EXISTS (
        SELECT 1
        FROM {{ ref('dim_users') }} AS test_users
        WHERE test_users.user_id = {{ user_id_column }}
          AND test_users.is_test_account
    )
{%- endmacro %}