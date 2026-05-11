# Cyclistic Bike-Share — Portfolio BI Project

A portfolio project for the **Google Business Intelligence Certificate** using the Cyclistic bike-share workplace scenario. Cyclistic is a fictional bike-share company partnered with New York City; its Customer Growth Team needs visibility into where rider demand exists and where the fleet is failing to meet it.

## The Question

> Does Cyclistic have enough bikes at the right station locations to meet rider demand across NYC?

A station with low trip counts isn't necessarily low-demand — it may simply be under-supplied. This project tries to separate the two.

## Datasets

- **Primary:** NYC Citi Bike Trips (2013–2015) — every trip's start/end station, time, bike ID, and rider type
- **Secondary:** US Census Bureau boundaries — for geographic context and population overlay
- **Course 2 additions:** NOAA GSOD daily weather (`bigquery-public-data.noaa_gsod`), US zip-code geometry (`bigquery-public-data.geo_us_boundaries.zip_codes`), and a user-uploaded NYC zip → borough/neighborhood CSV (loaded as `YOUR_PROJECT.cyclistic.zip_codes`)

## A3 Framework

Project thinking is structured as an A3. See [notes/a3_thinking.md](notes/a3_thinking.md) for the full version. In short:

- **Goal:** ensure sufficient bikes at the right stations to meet NYC rider demand
- **Current conditions:** uneven station demand, no visibility into supply gaps
- **Targets:** activity tiers via percentile reference lines, send/return balance matrix, fleet size = peak demand + 30% buffer, layered population growth context
- **Analysis questions:** station activity tiers, send/return balance, seasonal & rider-type variation, future demand from population shifts

Scenario coverage and remaining gaps are tracked in [docs/scenario_alignment.md](docs/scenario_alignment.md).

## Planned Deliverables

| # | Deliverable | Status |
|---|---|---|
| 1 | A3 framing of the business problem | Drafted ([notes/a3_thinking.md](notes/a3_thinking.md)) |
| 2 | Station classification SQL (high/med/low via 33rd/66th percentile) | Drafted ([sql/01_station_classification.sql](sql/01_station_classification.sql)) |
| 3 | User-type station classifier | Drafted ([sql/02_user_type_classification.sql](sql/02_user_type_classification.sql)) |
| 4 | Census growth distribution check | Drafted ([sql/03_census_growth_distribution.sql](sql/03_census_growth_distribution.sql)) |
| 5 | Census one-mile station overlay | Drafted ([sql/04_station_census_overlay.sql](sql/04_station_census_overlay.sql)) |
| 6 | Directional route flow lines and busy-station zones | Drafted ([sql/05_directional_route_flows.sql](sql/05_directional_route_flows.sql)) |
| 7 | Send/return balance ("safe zone matrix") per station | Planned |
| 8 | Fleet sizing model with adjustable buffer parameter | Drafted ([sql/07_fleet_buffer_calc.sql](sql/07_fleet_buffer_calc.sql)) |
| 9 | Daily station balance (congestion metric) | Drafted ([sql/08_daily_station_balance.sql](sql/08_daily_station_balance.sql)) |
| 10 | Destination popularity by total trip minutes | Drafted ([sql/09_destination_popularity.sql](sql/09_destination_popularity.sql)) |
| 11 | Seasonal & subscriber-vs-casual usage breakdown | Planned ([sql/06_seasonal_trends.sql](sql/06_seasonal_trends.sql)) |
| 12 | Population-overlay view to anticipate demand shifts | Planned |
| 13 | Dashboard — primary 2015 view + 2013–2015 trend, map with activity-tier filter, exit/return table, buffer slider, population layer | In Progress ([docs/ux_requirements.md](docs/ux_requirements.md)) |
| 14 | Executive summary (one-page) | Planned |
| 15 | Course 2 — A3 framing for data preparation | Drafted ([docs/google_bi/course_2_additions/a3_thinking.md](docs/google_bi/course_2_additions/a3_thinking.md)) |
| 16 | Course 2 — Stakeholder / Project / Strategy / Planning documents | Drafted ([docs/google_bi/course_2_additions/](docs/google_bi/course_2_additions/)) |
| 17 | Course 2 — Reporting target table: full year 2014–2015 | Drafted ([sql/10_reporting_table_full_year.sql](sql/10_reporting_table_full_year.sql)) |
| 18 | Course 2 — Reporting target table: summer (Jul–Sep) | Drafted ([sql/11_reporting_table_summer.sql](sql/11_reporting_table_summer.sql)) |
| 19 | Course 2 — Second dashboard page (`course2_reports.html`) wired to the new tables | Planned |

## Repository Layout

```
bike_bi/
├── docs/
│   └── google_bi/        Course materials (A3 template, scenario PDFs, blueprint decks)
├── sql/                  Analysis queries, numbered in execution order
├── notes/                Working notes — A3, design decisions, open questions
└── README.md             This file
```

## Setup And Run

These SQL files are written for **Google BigQuery** and use these datasets.

Public datasets (read-only, free tier):

- `bigquery-public-data.new_york_citibike`
- `bigquery-public-data.geo_census_tracts`
- `bigquery-public-data.census_bureau_acs`
- `bigquery-public-data.geo_us_boundaries` (Course 2 — zip-code polygons for spatial joins)
- `bigquery-public-data.noaa_gsod` (Course 2 — daily weather)

User-uploaded, one-time (Course 2):

- `YOUR_PROJECT.cyclistic.zip_codes` — upload the NYC zip-code CSV your colleague shared via BigQuery's **+ Add Data → Local file**. Auto-detect schema. Expected columns: `zip`, `borough`, `neighborhood`. The upload walkthrough is in [docs/google_bi/course_2_additions/module-4-cyclistic-datasets.en (1).pdf](docs/google_bi/course_2_additions/module-4-cyclistic-datasets.en%20(1).pdf).

Local Python setup:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Authenticate to Google Cloud:

```bash
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```

Run a query in the BigQuery console:

1. Open BigQuery in Google Cloud Console.
2. Paste one SQL file from `sql/`.
3. Run in this order for analysis:
   - `sql/01_station_classification.sql`
   - `sql/02_user_type_classification.sql`
   - `sql/03_census_growth_distribution.sql`
   - `sql/04_station_census_overlay.sql`
   - `sql/05_directional_route_flows.sql`
   - `sql/06_seasonal_trends.sql`
   - `sql/07_fleet_buffer_calc.sql`
   - `sql/08_daily_station_balance.sql`
   - `sql/09_destination_popularity.sql`
   - `sql/10_reporting_table_full_year.sql` — materializes `YOUR_PROJECT.cyclistic_bi.reporting_full_year` (Course 2)
   - `sql/11_reporting_table_summer.sql` — materializes `YOUR_PROJECT.cyclistic_bi.reporting_summer` (Course 2)

Optional CLI dry run, if the BigQuery CLI is installed:

```bash
bq query --use_legacy_sql=false --dry_run < sql/01_station_classification.sql
```

Optional CLI run and save to a table:

```bash
bq mk --dataset YOUR_PROJECT_ID:cyclistic_bi
bq query \
  --use_legacy_sql=false \
  --destination_table=YOUR_PROJECT_ID:cyclistic_bi.station_classification \
  --replace \
  < sql/01_station_classification.sql
```

Refresh dashboard CSV data:

```bash
python src/extract.py --project YOUR_PROJECT_ID --year 2015 --dry-run
python src/extract.py --project YOUR_PROJECT_ID --year 2015
```

The extractor writes CSVs to `data/`. Query outputs are ignored by git via
`data/*.csv`.

## Dashboard Design Intent

- **Primary:** 2015 data (most complete, post-ramp year)
- **Secondary:** 2013–2015 year-over-year trend
- **Map view:** trip flows drawn as lines, checkbox filters for activity tier (all / high / medium / low) and rider type (all / subscriber / customer), companion table driven by the same filters
- **Buffer parameter:** the slider works against a pre-computed peak-concurrency number from BigQuery ([sql/07_fleet_buffer_calc.sql](sql/07_fleet_buffer_calc.sql)). Math is done client-side, no re-query:
  - `total_fleet_needed = peak_bikes_in_use × (1 + buffer%)`
  - per-station allocation = `(station_trips ÷ total_trips) × total_fleet_needed`
  - default buffer **30%**; recommended **+5%** on top for a maintenance pool (bikes off the road)
- **Tertiary:** population shift context layer

Accessibility: large print and text-to-speech alternatives required (per stakeholder Sara Romero).
