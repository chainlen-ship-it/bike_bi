COURSE 2 · DATA PREPARATION

**Strategy Document**

*Cyclistic Fleet Intelligence — Google BI Certificate Course 2*

|                     |                                             |
|---------------------|---------------------------------------------|
| **BI Professional** | Chris Hainlen, Groveline LLC                |
| **Sponsor**         | Sara Romero, VP Marketing                   |
| **Stage**           | Data Preparation — ETL and Reporting Tables |
| **Date**            | May 2026                                    |

**PIPELINE ARCHITECTURE**

The Course 2 pipeline follows ELT pattern: data is loaded into BigQuery first (Extract + Load) and transformations happen inside the warehouse (Transform). This is the correct approach for BigQuery — the warehouse handles large-scale joins and aggregations efficiently, and there is no reason to transform data before it lands when the destination system is designed for that work.

The two reporting tables are the stable data layer between the analytical SQL queries and the dashboard. They replace on-demand queries with pre-computed, persistently available tables that any tool — Tableau, the HTML dashboard, or a future API — can read without re-running complex multi-join queries.

**WHY PRE-AGGREGATE TO 10-MINUTE DURATION BUCKETS**

The raw citibike_trips table has one row per trip. At millions of rows, dashboard rendering and CSV export are slow. Bucketing trip_duration to the nearest 10 minutes using ROUND(CAST(tripduration / 60 AS INT64), -1) collapses near-duplicate rows — two 23-minute trips and one 27-minute trip become three rows in the same bucket — while preserving the shape of the duration distribution. The tradeoff is acceptable: we lose sub-10-minute granularity on duration, which is not required by any stakeholder request.

**WHY TWO TABLES INSTEAD OF ONE**

The summer table (July–September) is queried independently and frequently as its own dashboard view. If we used one full-year table with a month filter, every summer chart load would scan the full 2014–2015 dataset before filtering. Materializing the summer table separately means summer queries only scan summer rows — a meaningful performance improvement at this data volume.

**COURSE 2 DASHBOARD PAGE STRATEGY**

frontend/source/course2_reports.html is a second dashboard page linked from the primary Fleet Intelligence dashboard. It uses the same CSS, the same dark theme, and the same accessibility patterns. The design is split into two halves reflecting the dual-persona requirement:

- Top half: executive KPI strip (Ernest Cox view) — four large KPI tiles showing total trips, average trip minutes, peak day, top borough. Clean, no interaction required, answers the executive's question in one glance.

- Bottom half: analyst drill-down (Tessa Blackwell view) — filter bar with year, borough, rider type, and precipitation controls driving a paginated results table with 20 rows per page. Full granularity, full filter control.

Both views read from the same reporting_full_year table. The same data layer serves both personas — the difference is the surface, not the source.

**MILESTONE PLAN**

|          |                        |                                                                                                                    |
|----------|------------------------|--------------------------------------------------------------------------------------------------------------------|
| **Week** | **Milestone**          | **Details**                                                                                                        |
| Week 1   | Data setup             | Upload NYC zip code CSV, validate spatial join against known station coordinates, confirm NOAA data range          |
| Week 2   | Full-year table        | Build and run reporting_full_year, validate row counts against Course 1 query totals, check borough label coverage |
| Week 3   | Summer table           | Build and run reporting_summer, validate July–September filter, cross-check against full-year table                |
| Week 4   | Course 2 page shell    | Build frontend/source/course2_reports.html shell, weather scatter and borough charts with placeholder data         |
| Week 5   | Wire dual-persona view | Executive KPI strip and analyst drill-down table wired to real CSVs, filter interactions tested                    |
| Week 6   | Extract and validate   | Run backend/app/src/extract.py for all reporting tables, validate CSV outputs, confirm dashboard loads correctly   |

*Cyclistic Fleet Intelligence Dashboard · Google BI Certificate Portfolio · Chris Hainlen · May 2026*
