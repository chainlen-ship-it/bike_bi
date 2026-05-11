# A3 Thinking — Cyclistic Course 2: Data Preparation

**Goal:** Combine bike, weather, zip-code, and boundary data into materialized reporting tables that feed both an executive overview and an analyst drill-down on the Cyclistic dashboard.

## 1. Background

Course 1 produced 9 ad-hoc SQL queries against NYC Citi Bike trip data and the Course 1 planning documents. Course 2 is the **Data Preparation** stage of the BI workflow: extract, transform, and combine the data into target reporting tables that can be loaded into Tableau or read by the existing HTML dashboard.

Two new sources arrive in Course 2:

- **NOAA GSOD** daily weather (`bigquery-public-data.noaa_gsod.gsod20*`), filtered to wban `94728` (Central Park) per the course query
- An **NYC zip-code CSV** uploaded by a colleague that maps zip → neighborhood + borough (loaded as `cyclistic.zip_codes` in your own GCP project)

A third dataset, `bigquery-public-data.geo_us_boundaries.zip_codes`, is used for spatial joins (`ST_WITHIN`) between trip start/end coordinates and zip polygons.

## 2. Current Conditions

- The 9 Course 1 queries return ad-hoc result sets, not materialized tables. They can't be efficiently shared with non-engineer stakeholders or with Tableau.
- Weather is not joined to trip data; we cannot answer "does ridership drop in rain?"
- Locations are coordinates only; there are no neighborhood or borough labels — readability for executive viewers is poor.
- Stakeholder personas have diverged in observed use:
  - **Ernest Cox (VP Product Development)** — wants high-level overviews; rarely drills in.
  - **Tessa Blackwell (Data Analytics)** — explores the data in depth; spends a lot of time in dashboard views.
  - The current single-view design serves neither persona well.

## 3. Goals / Targets

- Two materialized target tables in BigQuery:
  - `reporting_full_year` — all of 2014–2015
  - `reporting_summer` — July, August, September of 2014–2015
- Each row enriched with:
  - usertype (Subscriber / Customer)
  - start zip / borough / neighborhood
  - end zip / borough / neighborhood
  - start_day / stop_day (DATE_ADD +5 years applied for the fictional-project "recent" feel)
  - daily mean temperature, mean wind speed, total precipitation
  - 10-minute trip-duration bucket
  - trip_count
- **Tableau-ready and CSV-export-ready** so the same tables feed Tableau directly *and* the existing HTML dashboard's `data/` directory.
- **Dual-persona dashboard support:** an executive overview surface plus an analyst drill-down surface, both backed by the same tables.

## 4. Analysis Questions the Data Must Answer (additions to Course 1)

- How does daily precipitation impact trip volume per borough?
- Do summer (Jul–Sep) peaks differ across boroughs and neighborhoods?
- Do subscriber vs casual patterns diverge in inclement weather?
- Is the weather effect different at 10-minute trip durations vs longer durations?

## Dashboard Intent (delta from Course 1)

- New page `course2_reports.html`, linked from the existing dashboard via a "Course 2 Reports →" nav item. Same CSS, same accessibility patterns.
- New charts on this page:
  - **Borough × weather**: trip volume vs daily precipitation, faceted by borough
  - **Summer borough breakdown**: bar chart of trips per borough for July–September
  - **Persona dual view**: an executive KPI strip at the top with broad numbers; an analyst drill-down table below with full filter controls
- The same materialized tables are the source of truth for a Tableau workbook (Course 3 deliverable).

## Notes / Conventions Adopted from the Course Query

- `DATE_ADD(..., INTERVAL 5 YEAR)` shifts dates forward so the dashboard appears recent. Removable for a true historical view.
- `ROUND(CAST(tripduration / 60 AS INT64), -1)` buckets trip durations to the nearest 10 minutes to reduce row count without losing distribution shape.
- `WEA.wban = '94728'` — a single Central Park weather station is used as a city-wide proxy.
