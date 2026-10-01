import json
from pathlib import Path

import requests
from google.cloud import bigquery


PROJECT_ID = "pokemon-data-challenge"
DATASET_ID = "pokemon_reference"
TABLE_ID = "pokemon_species"

MAX_POKEMON_ID = 721

ROOT_DIR = Path(__file__).resolve().parents[2]
OUTPUT_DIR = ROOT_DIR / "data_pokemon" / "data" / "reference"
OUTPUT_FILE = OUTPUT_DIR / "pokemon_reference.json"


def fetch_pokemon_species(pokemon_id: int) -> dict:
    url = f"https://pokeapi.co/api/v2/pokemon-species/{pokemon_id}/"

    response = requests.get(
        url,
        headers={"User-Agent": "pokemon-data-challenge/1.0"},
        timeout=30,
    )
    response.raise_for_status()

    data = response.json()

    return {
        "pokemon_id": data["id"],
        "default_name": data["name"],
    }


def save_reference_data(records: list[dict]) -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    with OUTPUT_FILE.open("w", encoding="utf-8") as file:
        json.dump(records, file, indent=2, ensure_ascii=False)

    print(f"Saved {len(records)} records to {OUTPUT_FILE}")


def load_to_bigquery(records: list[dict]) -> None:
    client = bigquery.Client(project=PROJECT_ID)

    table_id = f"{PROJECT_ID}.{DATASET_ID}.{TABLE_ID}"

    job_config = bigquery.LoadJobConfig(
        schema=[
            bigquery.SchemaField("pokemon_id", "INT64"),
            bigquery.SchemaField("default_name", "STRING"),
        ],
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
    )

    load_job = client.load_table_from_json(
        records,
        table_id,
        job_config=job_config,
    )

    load_job.result()

    table = client.get_table(table_id)

    print(f"Loaded {table.num_rows} rows into {table_id}")


def main() -> None:
    records = []

    for pokemon_id in range(1, MAX_POKEMON_ID + 1):
        record = fetch_pokemon_species(pokemon_id)
        records.append(record)

        print(
            f"Fetched {record['pokemon_id']}: "
            f"{record['default_name']}"
        )

    save_reference_data(records)
    load_to_bigquery(records)


if __name__ == "__main__":
    main()