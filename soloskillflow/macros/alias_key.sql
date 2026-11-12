{# Ключ для пошуку в довіднику: без пробілів і підкреслень, нижній регістр.
   'Paid Social', 'paid_social', ' PaidSocial ' → 'paidsocial' #}
{% macro alias_key(column) -%}
    lower(replace(replace(trim({{ column }}), ' ', ''), '_', ''))
{%- endmacro %}