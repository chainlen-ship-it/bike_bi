# extract.py
# Pulls query results from BigQuery and exports to backend/data/.
# Configure via .env, then run this to refresh dashboard data before
# opening frontend/source/dashboard.html.
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
#   backend/data/stations.csv
#   backend/data/seasonal.csv
#   backend/data/fleet.csv
#   backend/data/flows.csv
#   backend/data/population.csv
#   backend/data/daily_balance.csv
#   backend/data/destinations.csv
#
# Usage:
#   python backend/app/src/extract.py

from __future__ import annotations

import argparse
import os
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


DEFAULT_REPO_DIR = Path(__file__).resolve().parents[3]
DEFAULT_ROOT_DIR = Path(__file__).resolve().parents[2]
DEFAULT_ENV_FILE = DEFAULT_REPO_DIR / ".env"
VALID_YEARS = (2013, 2014, 2015)


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


@dataclass(frozen=True)
class ExtractConfig:
    root_dir: Path
    sql_dir: Path
    data_dir: Path
    year_from: int
    project: str
    google_auth_launch: bool


def load_env(env_file: Path) -> dict[str, str]:
    if not env_file.exists():
        return {}

    values: dict[str, str] = {}
    for line_number, raw_line in enumerate(env_file.read_text(encoding="utf-8").splitlines(), start=1):
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("export "):
            line = line.removeprefix("export ").strip()
        if "=" not in line:
            raise ValueError(f"{env_file}:{line_number}: expected KEY=value")

        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip().strip("\"'")
        if not key:
            raise ValueError(f"{env_file}:{line_number}: missing key before '='")
        values[key] = value

    return values


def env_value(env: dict[str, str], key: str, default: str | None = None) -> str | None:
    return os.environ.get(key) or env.get(key) or default


def apply_env(env: dict[str, str]) -> None:
    for key, value in env.items():
        os.environ.setdefault(key, value)


def env_bool(env: dict[str, str], key: str, default: bool = False) -> bool:
    value = env_value(env, key)
    if value is None:
        return default
    normalized = value.strip().lower()
    if normalized in {"1", "true", "yes", "y", "on"}:
        return True
    if normalized in {"0", "false", "no", "n", "off"}:
        return False
    raise ValueError(f"{key} must be true/false, got {value!r}")


def resolve_path(value: str | None, root_dir: Path, default: Path) -> Path:
    if not value:
        return default

    path = Path(value).expanduser()
    if path.is_absolute():
        return path
    return root_dir / path


def build_config(args: argparse.Namespace) -> ExtractConfig:
    env_file = args.env_file.expanduser()
    if not env_file.is_absolute():
        env_file = DEFAULT_REPO_DIR / env_file

    env = load_env(env_file)
    apply_env(env)

    root_dir = Path(env_value(env, "ROOT_DIR", str(DEFAULT_ROOT_DIR))).expanduser()
    if not root_dir.is_absolute():
        root_dir = DEFAULT_REPO_DIR / root_dir
    root_dir = root_dir.resolve()

    sql_dir = resolve_path(env_value(env, "SQL_DIR"), root_dir, root_dir / "sql").resolve()
    data_dir = resolve_path(env_value(env, "DATA_DIR"), root_dir, root_dir / "data").resolve()

    year_raw = str(args.year or env_value(env, "YEAR_FROM", "2015"))
    year_from = int(year_raw)
    if year_from not in VALID_YEARS:
        valid = ", ".join(str(year) for year in VALID_YEARS)
        raise ValueError(f"YEAR_FROM must be one of {valid}, got {year_from}")

    project = args.project or env_value(env, "YOUR_PROJECT") or env_value(env, "GCP_PROJECT")
    if not project or project == "YOUR_PROJECT_ID":
        raise ValueError("Set YOUR_PROJECT in .env or pass --project.")

    return ExtractConfig(
        root_dir=root_dir,
        sql_dir=sql_dir,
        data_dir=data_dir,
        year_from=year_from,
        project=project,
        google_auth_launch=env_bool(env, "GOOGLE_AUTH_LAUNCH"),
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Export Cyclistic BigQuery query results to local CSV files."
    )
    parser.add_argument(
        "--env-file",
        type=Path,
        default=DEFAULT_ENV_FILE,
        help="Path to the env file. Defaults to .env in the repository root.",
    )
    parser.add_argument(
        "--project",
        default=None,
        help="Optional override for YOUR_PROJECT in .env.",
    )
    parser.add_argument(
        "--year",
        type=int,
        default=None,
        choices=VALID_YEARS,
        help="Optional override for YEAR_FROM in .env.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=None,
        help="Optional override for DATA_DIR in .env.",
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


def maybe_launch_google_auth(config: ExtractConfig) -> None:
    if not config.google_auth_launch:
        return

    subprocess.run(["gcloud", "auth", "application-default", "login"], check=True)
    subprocess.run(["gcloud", "config", "set", "project", config.project], check=True)


def read_sql(sql_dir: Path, sql_file: str, project: str) -> str:
    return (sql_dir / sql_file).read_text(encoding="utf-8").replace("YOUR_PROJECT", project)


def wrap_query(sql: str, spec: ExportSpec, year: int, limit: int | None) -> str:
    sql = sql.replace(";", "")
    wrapped = f"SELECT * FROM (\n{sql}\n)"

    if spec.filter_year:
        wrapped += f"\nWHERE EXTRACT(YEAR FROM trip_date) = {year}"

    if limit is not None:
        wrapped += f"\nLIMIT {limit}"

    return wrapped


def run_dry_run(client, config: ExtractConfig, specs: Iterable[ExportSpec], limit: int | None) -> None:
    from google.cloud import bigquery

    for spec in specs:
        sql = wrap_query(read_sql(config.sql_dir, spec.sql_file, config.project), spec, config.year_from, limit)
        job_config = bigquery.QueryJobConfig(dry_run=True, use_query_cache=False)
        job = client.query(sql, project=config.project, job_config=job_config)
        print(f"{spec.sql_file}: {job.total_bytes_processed:,} bytes")


def export_csvs(client, config: ExtractConfig, specs: Iterable[ExportSpec], output_dir: Path, limit: int | None) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)

    for spec in specs:
        sql = wrap_query(read_sql(config.sql_dir, spec.sql_file, config.project), spec, config.year_from, limit)
        output_path = output_dir / spec.output_file

        print(f"Running {spec.sql_file} -> {output_path}")
        job = client.query(sql, project=config.project)
        dataframe = job.result().to_dataframe(create_bqstorage_client=False)
        dataframe.to_csv(output_path, index=False)
        print(f"  wrote {len(dataframe):,} rows")


def build_bigquery_client(project: str):
    from google.cloud import bigquery

    access_token = os.environ.get("GOOGLE_OAUTH_ACCESS_TOKEN")
    if access_token:
        from google.oauth2.credentials import Credentials

        credentials = Credentials(token=access_token)
        return bigquery.Client(project=project, credentials=credentials)

    return bigquery.Client(project=project)


def main() -> None:
    args = parse_args()
    config = build_config(args)
    output_dir = args.output_dir.resolve() if args.output_dir else config.data_dir

    maybe_launch_google_auth(config)

    client = build_bigquery_client(config.project)

    if args.dry_run:
        run_dry_run(client, config, EXPORTS, args.limit)
        return

    export_csvs(client, config, EXPORTS, output_dir, args.limit)


if __name__ == "__main__":
    main()
