"""Ingest сирих даних SkillFlow з бакетів S3 і GCS у bronze (Postgres).

Запуск з кореня проєкту:  python ingest.py
Адреси бакетів — у .dlt/config.toml, ключі доступу — у .dlt/secrets.toml.
"""
import json
from datetime import date, datetime

import dlt
from dlt.sources.filesystem import filesystem, read_csv
from dlt.sources.helpers import requests  # як requests, але з повторами при збоях

from bronze_contract import NBU_SCHEMA_CONTRACT, SCHEMA_CONTRACT, column_hints

# бакет → назва pipeline і таблиці з форматом файлів.
# Назву pipeline не міняємо: за нею dlt знаходить потрібні ключі в secrets.toml.
SOURCES = {
    "s3": {
        "pipeline_name": "s3_ingest",
        "tables": {
            "users": "csv",
            "events": "jsonl",
            "subscriptions": "csv",
            "experiments": "csv",
            "marketing_spend": "csv",
        },
    },
    "gcs": {
        "pipeline_name": "gcs_ingest",
        "tables": {
            "app_errors": "csv",
            "lesson_progress": "csv",
            "lessons": "csv",
            "payments": "jsonl",
            "support_tickets": "csv",
        },
    },
}

NBU_URL = "https://bank.gov.ua/NBU_Exchange/exchange_site"

@dlt.transformer(standalone=True)
def read_jsonl_blocks(items, chunksize=10_000, block_mb=2):
    """Читає jsonl потоково: блоками по block_mb МБ, віддає рядки пачками по chunksize.

    Пам'ять залежить від розміру блока, а не від розміру файлу.
    """
    block_size = block_mb * 1024 * 1024
    for file_obj in items:
        with file_obj.open(mode="rb", block_size=block_size) as f:
            rows = []
            tail = b""  # неповний рядок з кінця попереднього блока
            while block := f.read(block_size):
                lines = (tail + block).split(b"\n")
                tail = lines.pop()
                for line in lines:
                    if line.strip():
                        rows.append(json.loads(line))
                        if len(rows) >= chunksize:
                            yield rows
                            rows = []
            if tail.strip():
                rows.append(json.loads(tail))
            if rows:
                yield rows


def bucket_resources(bucket_url, tables):
    """Один dlt-ресурс на таблицю: файли з бакета → читач за форматом → контракт."""
    resources = []
    for table, fmt in tables.items():
        files = filesystem(bucket_url=bucket_url, file_glob=f"table={table}/**/*.{fmt}")
        reader = read_csv() if fmt == "csv" else read_jsonl_blocks()
        resource = (files | reader).with_name(table)
        # явні типи колонок і правила, що робити, коли дані їм не відповідають
        resource.apply_hints(columns=column_hints(table), schema_contract=SCHEMA_CONTRACT)
        resources.append(resource)
    return resources


def load_bucket(source_key):
    """Завантажує всі таблиці одного бакета в bronze (повна заміна)."""
    source = SOURCES[source_key]
    bucket_url = dlt.config[f"buckets.{source_key}"]

    # pipeline створюємо ДО ресурсів: ключі доступу dlt шукає за назвою pipeline
    pipeline = dlt.pipeline(
        pipeline_name=source["pipeline_name"],
        destination="postgres",
        dataset_name="bronze",
        progress="tqdm",
    )
    info = pipeline.run(
        bucket_resources(bucket_url, source["tables"]),
        write_disposition="replace",
    )
    print(info)


@dlt.resource(
    name="nbu_rates",
    write_disposition="merge",
    primary_key=("cc", "exchangedate"),
    columns=column_hints("nbu_rates"),
    schema_contract=NBU_SCHEMA_CONTRACT,
)
def nbu_rates(currencies, rate_date=dlt.sources.incremental("rate_date")):
    """Курси НБУ від останньої завантаженої дати до сьогодні: один запит на валюту.

    Перший запуск починає з initial_value, наступні — з дати, яку dlt запам'ятав.
    """
    start_date = date.fromisoformat(rate_date.last_value)
    end_date = date.today()
    print(f"НБУ: запитую курси з {start_date} по {end_date}")
    for cc in currencies:
        params = {
            "start": start_date.strftime("%Y%m%d"),
            "end": end_date.strftime("%Y%m%d"),
            "valcode": cc,
            "sort": "exchangedate",
            "order": "asc",
            "json": "",
        }
        # повтори при 429/5xx і обривах зв'язку; після невдалих спроб — помилка
        response = requests.get(NBU_URL, params=params, timeout=30)
        rows = response.json()
        for row in rows:
            # ISO-дата для курсора: "17.11.2026" → "2026-11-17"
            row["rate_date"] = datetime.strptime(row["exchangedate"], "%d.%m.%Y").date().isoformat()
        yield rows


def load_nbu():
    """Довантажує нові курси НБУ в bronze (merge за ключем валюта + дата)."""
    pipeline = dlt.pipeline(
        pipeline_name="nbu_ingest",
        destination="postgres",
        dataset_name="bronze",
    )
    rates = nbu_rates(
        dlt.config["nbu.currencies"],
        rate_date=dlt.sources.incremental(
            "rate_date", initial_value=dlt.config["nbu.start_date"]
        ),
    )
    info = pipeline.run(rates)
    print(info)


def main():
    for source_key in SOURCES:
        load_bucket(source_key)
    load_nbu()


if __name__ == "__main__":
    main()