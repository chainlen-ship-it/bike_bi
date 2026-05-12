COURSE 2 · DATA PREPARATION

**Project Requirements Document**

*Cyclistic Fleet Intelligence — Google BI Certificate Course 2*

|                     |                              |
|---------------------|------------------------------|
| **BI Professional** | Chris Hainlen, Groveline LLC |
| **Project Manager** | Shareefah Hakimi             |
| **Sponsor**         | Sara Romero, VP Marketing    |
| **Date**            | May 2026                     |

**STAGE GOAL**

Combine NYC Citi Bike trip data with NOAA daily weather and US Census geographic enrichment into two materialized BigQuery reporting tables. These tables become the persistent data layer for the dashboard, replacing the 9 ad-hoc Course 1 queries with a stable, shareable, Tableau-ready and HTML-dashboard-ready data source.

**TARGET TABLES**

**reporting_full_year:** All of 2014–2015, one row per (usertype, start zip, borough, neighborhood, end zip, borough, neighborhood, date, weather, 10-minute trip duration bucket) with trip count. Powers the full-year borough breakdown, weather impact scatter, and analyst drill-down table.

**reporting_summer:** July, August, September of 2014–2015, same schema as full-year table. Powers the summer borough breakdown chart. Materialized separately for query performance — the summer view is queried independently and frequently.

**SCHEMA**

|                         |          |                                                           |
|-------------------------|----------|-----------------------------------------------------------|
| **Field**               | **Type** | **Description**                                           |
| usertype                | STRING   | Subscriber or Customer                                    |
| zip_code_start          | STRING   | Start station zip code (from geo boundary join)           |
| borough_start           | STRING   | Start borough name (from zip code CSV)                    |
| neighborhood_start      | STRING   | Start neighborhood name (from zip code CSV)               |
| zip_code_end            | STRING   | End station zip code                                      |
| borough_end             | STRING   | End borough name                                          |
| neighborhood_end        | STRING   | End neighborhood name                                     |
| start_day               | DATE     | Trip start date (DATE_ADD +5 years for fictional recency) |
| stop_day                | DATE     | Trip end date                                             |
| day_mean_temperature    | FLOAT    | Daily mean temp °F from NOAA GSOD Central Park            |
| day_mean_wind_speed     | FLOAT    | Daily mean wind speed from NOAA GSOD                      |
| day_total_precipitation | FLOAT    | Daily total precipitation inches from NOAA GSOD           |
| trip_minutes            | INTEGER  | Trip duration rounded to nearest 10 minutes               |
| trip_count              | INTEGER  | Count of trips matching all dimension values in this row  |

**ASSUMPTIONS AND LIMITATIONS**

- NOAA GSOD records daily precipitation totals, not hourly. Any precipitation on a trip day is treated as potentially impacting ridership — this is a simplification, documented in the dashboard.

- Central Park weather station (wban 94728) used as city-wide proxy. Precipitation intensity and timing vary across the five boroughs.

- DATE_ADD +5 years applied to dates so the dashboard appears recent — this is a fictional-project convention. Remove for true historical analysis.

- Trip duration bucketed to nearest 10 minutes to reduce row count. Distribution shape is preserved.

- Stations outside the uploaded zip code CSV will show null neighborhood and borough labels.

*Cyclistic Fleet Intelligence Dashboard · Google BI Certificate Portfolio · Chris Hainlen · May 2026*
