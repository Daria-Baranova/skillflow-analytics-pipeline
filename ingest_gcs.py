import json

import dlt
from dlt.sources.filesystem import filesystem, read_csv

BUCKET_URL = "gs://skillflow-v2-raw-gcs-daria/raw/source=skillflow"

TABLES = {
    "app_errors": "csv",
    "lesson_progress": "csv",
    "lessons": "csv",
    "payments": "jsonl",
    "support_tickets": "csv",
}


@dlt.transformer(standalone=True)
def read_jsonl_fast(items, chunksize=10_000):
    for file_obj in items:
        with file_obj.open() as f:
            lines = f.read().splitlines()
        for i in range(0, len(lines), chunksize):
            yield [json.loads(line) for line in lines[i:i + chunksize]]


pipeline = dlt.pipeline(
    pipeline_name="gcs_ingest",
    destination="postgres",
    dataset_name="bronze",
    progress="tqdm",
)

resources = []
for table, fmt in TABLES.items():
    files = filesystem(bucket_url=BUCKET_URL, file_glob=f"table={table}/**/*.{fmt}")
    reader = read_csv() if fmt == "csv" else read_jsonl_fast()
    resources.append((files | reader).with_name(table))

info = pipeline.run(resources, write_disposition="replace")
print(info)