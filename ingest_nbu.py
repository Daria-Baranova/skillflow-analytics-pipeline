import dlt
import requests

URL = "https://bank.gov.ua/NBU_Exchange/exchange_site"
START = "20260601"
END = "20260831"
CURRENCIES = ["usd", "eur"]

@dlt.resource(name="nbu_rates")
def nbu_rates():
    for cc in CURRENCIES:
        params = {
            "start": START,
            "end": END,
            "valcode": cc,
            "sort": "exchangedate",
            "order": "asc",
            "json": "",
        }
        response = requests.get(URL, params=params, timeout=30)
        response.raise_for_status()
        yield response.json()

pipeline = dlt.pipeline(
    pipeline_name="nbu_ingest",
    destination="postgres",
    dataset_name="bronze",
)

info = pipeline.run(nbu_rates(), write_disposition="replace")
print(info)
