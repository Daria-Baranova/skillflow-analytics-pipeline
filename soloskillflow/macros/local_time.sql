{# Дата в бізнес-часовому поясі (vars: reporting_tz) #}
{% macro to_local_date(column) -%}
    ({{ column }} AT TIME ZONE '{{ var("reporting_tz") }}')::DATE
{%- endmacro %}

{# Понеділок тижня в бізнес-часовому поясі #}
{% macro to_local_week(column) -%}
    date_trunc('week', {{ column }} AT TIME ZONE '{{ var("reporting_tz") }}')::DATE
{%- endmacro %}