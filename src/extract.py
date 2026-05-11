# extract.py
# Pulls query results from BigQuery and exports to data/
# Run this to refresh dashboard data before opening dashboard.html
#
# Queries executed in order:
#   01_station_classification.sql
#   06_seasonal_trends.sql
#   07_fleet_buffer_calc.sql
#   05_directional_route_flows.sql
#   04_station_census_overlay.sql
#   08_daily_station_balance.sql
#   09_destination_popularity.sql
#
# Outputs:
#   data/stations.csv
#   data/seasonal.csv
#   data/fleet.csv
#   data/flows.csv
#   data/population.csv
#   data/daily_balance.csv
#   data/destinations.csv
#
# Usage:
#   python src/extract.py --year 2015 --project YOUR_GCP_PROJECT_ID

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


ROOT_DIR = Path(__file__).resolve().parents[1]
SQL_DIR = ROOT_DIR / "sql"
DATA_DIR = ROOT_DIR / "data"


@dataclass(frozen=True)
class ExportSpec:
    sql_file: str
    output_file: str
    filter_year: bool = False


EXPORTS: tuple[ExportSpec, ...] = (
    ExportSpec("01_station_classification.sql", "stations.csv"),
    ExportSpec("06_seasonal_trends.sql", "seasonal.csv"),
    ExportSpec("07_fleet_buffer_calc.sql", "fleet.csv"),
    ExportSpec("05_directional_route_flows.sql", "flows.csv"),
    ExportSpec("04_station_census_overlay.sql", "population.csv"),
    ExportSpec("08_daily_station_balance.sql", "daily_balance.csv", filter_year=True),
    ExportSpec("09_destination_popularity.sql", "destinations.csv"),
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Export Cyclistic BigQuery query results to local CSV files."
    )
    parser.add_argument(
        "--project",
        required=True,
        help="Google Cloud project ID used for BigQuery jobs.",
    )
    parser.add_argument(
        "--year",
        type=int,
        default=2015,
        choices=(2013, 2014, 2015),
        help="Dashboard focus year. Daily balance exports are filtered to this year.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=DATA_DIR,
        help="Directory where CSV files are written. Defaults to data/.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        help="Optional row limit for quick smoke tests.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate queries and print estimated bytes without exporting CSVs.",
    )
    return parser.parse_args()


def read_sql(sql_file: str) -> str:
    return (SQL_DIR / sql_file).read_text(encoding="utf-8")


def wrap_query(sql: str, spec: ExportSpec, year: int, limit: int | None) -> str:
    sql = sql.replace(";", "")
    wrapped = f"SELECT * FROM (\n{sql}\n)"

    if spec.filter_year:
        wrapped += f"\nWHERE EXTRACT(YEAR FROM trip_date) = {year}"

    if limit is not None:
        wrapped += f"\nLIMIT {limit}"

    return wrapped


def run_dry_run(client, project: str, specs: Iterable[ExportSpec], year: int, limit: int | None) -> None:
    from google.cloud import bigquery

    for spec in specs:
        sql = wrap_query(read_sql(spec.sql_file), spec, year, limit)
        job_config = bigquery.QueryJobConfig(dry_run=True, use_query_cache=False)
        job = client.query(sql, project=project, job_config=job_config)
        print(f"{spec.sql_file}: {job.total_bytes_processed:,} bytes")


def export_csvs(client, project: str, specs: Iterable[ExportSpec], year: int, output_dir: Path, limit: int | None) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)

    for spec in specs:
        sql = wrap_query(read_sql(spec.sql_file), spec, year, limit)
        output_path = output_dir / spec.output_file

        print(f"Running {spec.sql_file} -> {output_path}")
        job = client.query(sql, project=project)
        dataframe = job.result().to_dataframe(create_bqstorage_client=False)
        dataframe.to_csv(output_path, index=False)
        print(f"  wrote {len(dataframe):,} rows")


def main() -> None:
    args = parse_args()

    from google.cloud import bigquery

    client = bigquery.Client(project=args.project)

    if args.dry_run:
        run_dry_run(client, args.project, EXPORTS, args.year, args.limit)
        return

    export_csvs(client, args.project, EXPORTS, args.year, args.output_dir, args.limit)


if __name__ == "__main__":
    main()
