"""Контракт даних bronze: які колонки і якого типу ми чекаємо від джерел.

dlt перевіряє кожне завантаження за цим контрактом (SCHEMA_CONTRACT):
- нова таблиця → можна (tables: evolve), інакше перший запуск на чистій базі впаде;
- нова колонка в джерелі → помилка (columns: freeze);
- значення не того типу, напр. "N/A" у числовій колонці → помилка (data_type: freeze).

text — для «брудних» колонок, де значення в різних форматах
("485,80", "100%", "$9.99", "24/06/2026 10:55"). Їх зберігаємо як є,
а розбираємо в silver (dbt), де є тести.
"""

SCHEMA_CONTRACT = {"tables": "evolve", "columns": "freeze", "data_type": "freeze"}

# НБУ — чуже API: нові поля від банку дозволяємо, а зміну типу — ні
NBU_SCHEMA_CONTRACT = {"columns": "evolve", "data_type": "freeze"}

COLUMNS = {
    # ---------- S3 ----------
    "users": {
        "user_id": "bigint",
        "signup_at": "text",  # три формати дати, розбираємо в stg_users
        "country": "text",
        "device": "text",
        "traffic_source": "text",
        "learning_goal": "text",
        "age_band": "text",
        "is_test_account": "bigint",
    },
    "events": {
        "event_id": "text",
        "user_id": "bigint",
        "event_name": "text",
        "event_ts": "timestamp",
        "platform": "text",
        "session_id": "text",
        "properties__source": "text",
        "properties__lesson_id": "text",
        "properties__step": "bigint",
        "properties__trial_type": "text",
    },
    "subscriptions": {
        "subscription_id": "text",
        "user_id": "bigint",
        "trial_started_at": "timestamp",
        "trial_type": "text",
        "plan": "text",
        "trial_status": "text",
        "cancelled_at": "timestamp",
        "converted_at": "timestamp",
    },
    "experiments": {
        "experiment_id": "text",
        "user_id": "bigint",
        "experiment_group": "text",
        "assigned_at": "timestamp",
        "assignment_source": "text",
    },
    "marketing_spend": {
        "spend_date": "text",
        "channel": "text",
        "country": "text",
        "spend_usd": "text",  # "485,80" — кома замість крапки
        "impressions": "bigint",
        "clicks": "bigint",
    },
    # ---------- GCS ----------
    "app_errors": {
        "error_id": "text",
        "user_id": "bigint",
        "occurred_at": "timestamp",
        "screen": "text",
        "error_code": "text",
        "message": "text",
    },
    "lesson_progress": {
        "progress_id": "bigint",
        "user_id": "bigint",
        "lesson_id": "text",
        "started_at": "timestamp",
        "completed_at": "timestamp",
        "completion_pct": "text",  # "100%"
    },
    "lessons": {
        "lesson_id": "text",
        "title": "text",
        "topic": "text",
        "level": "text",
        "duration_min": "text",  # "30" або "30 min"
        "is_active": "text",  # "yes" / "1" / "true"
    },
    "payments": {
        "payment_id": "text",
        "user_id": "bigint",
        "subscription_id": "text",
        "paid_at": "timestamp",
        "amount_raw": "text",  # "$9.99", "416,25 UAH"
        "currency": "text",
        "status": "text",
        "is_refund": "bigint",
    },
    "support_tickets": {
        "ticket_id": "text",
        "user_id": "bigint",
        "created_at": "timestamp",
        "category": "text",
        "severity": "text",
        "resolved_at": "timestamp",
    },
    # ---------- НБУ: лише колонки, які читає silver ----------
    "nbu_rates": {
        "cc": "text",
        "exchangedate": "text",
        "rate_date": "text",
        "calcdate": "text",
        "rate_per_unit": "double",  # курс — число, не текст
    },
}


def column_hints(table):
    """{"user_id": "bigint"} → {"user_id": {"data_type": "bigint"}} — формат, який чекає dlt."""
    return {name: {"data_type": data_type} for name, data_type in COLUMNS[table].items()}
