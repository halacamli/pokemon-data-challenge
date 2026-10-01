import json
from datetime import datetime, timezone
from pathlib import Path

from google.cloud import bigquery


PROJECT_ID = "pokemon-data-challenge"
DATASET_ID = "pokemon_raw"

ROOT_DIR = Path(__file__).resolve().parents[1]
RAW_DATA_DIR = ROOT_DIR / "raw"

SOURCES = {
    "source_a": RAW_DATA_DIR / "pokemon_source_a.json",
    "source_b": RAW_DATA_DIR / "pokemon_source_b.json",
}


def load_source(client: bigquery.Client, table_name: str, file_path: Path) -> None:
    with file_path.open("r", encoding="utf-8") as file:
        records = json.load(file)

    loaded_at = datetime.now(timezone.utc).isoformat()

    rows = [
        {
            "payload": record,
            "source_file": file_path.name,
            "loaded_at": loaded_at,
        }
        for record in records
    ]

    table_id = f"{PROJECT_ID}.{DATASET_ID}.{table_name}"

    job_config = bigquery.LoadJobConfig(
        schema=[
            bigquery.SchemaField("payload", "JSON"),
            bigquery.SchemaField("source_file", "STRING"),
            bigquery.SchemaField("loaded_at", "TIMESTAMP"),
        ],
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
    )

    load_job = client.load_table_from_json(
        rows,
        table_id,
        job_config=job_config,
    )

    load_job.result()

    table = client.get_table(table_id)
    print(f"Loaded {table.num_rows} rows into {table_id}")


def main() -> None:
    client = bigquery.Client(project=PROJECT_ID)

    for table_name, file_path in SOURCES.items():
        load_source(client, table_name, file_path)


if __name__ == "__main__":
    main()