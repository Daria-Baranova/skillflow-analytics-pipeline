"""Ingest сирих даних SkillFlow з бакетів S3 і GCS у bronze (Postgres).

Запуск з кореня проєкту:  python ingest.py
Адреси бакетів — у .dlt/config.toml, ключі доступу — у .dlt/secrets.toml.
"""
import json

import dlt
from dlt.sources.filesystem import filesystem, read_csv

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


@dlt.transformer(standalone=True)
def read_jsonl_fast(items, chunksize=10_000):
    """Читає jsonl-файл і віддає рядки пачками по chunksize."""
    for file_obj in items:
        with file_obj.open() as f:
            lines = f.read().splitlines()
        for i in range(0, len(lines), chunksize):
            yield [json.loads(line) for line in lines[i:i + chunksize]]


def bucket_resources(bucket_url, tables):
    """Один dlt-ресурс на таблицю: файли з бакета → читач за форматом."""
    resources = []
    for table, fmt in tables.items():
        files = filesystem(bucket_url=bucket_url, file_glob=f"table={table}/**/*.{fmt}")
        reader = read_csv() if fmt == "csv" else read_jsonl_fast()
        resources.append((files | reader).with_name(table))
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


def main():
    for source_key in SOURCES:
        load_bucket(source_key)


if __name__ == "__main__":
    main()