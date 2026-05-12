-- 10_reporting_table_full_year.sql
--
-- Course 2 reporting target table. Materializes one row per
-- (usertype, start_zip, start_borough, start_neighborhood,
--  end_zip, end_borough, end_neighborhood, start_day, stop_day,
--  daily_temp, daily_wind, daily_precip, 10-minute trip-duration bucket)
-- with a COUNT of trips. Powers the Course 2 dashboard page.
--
-- Combines four data sources:
--   * NYC Citi Bike Trips           (bigquery-public-data.new_york_citibike.citibike_trips)
--   * US zip-code geometry          (bigquery-public-data.geo_us_boundaries.zip_codes)
--   * NOAA GSOD daily weather       (bigquery-public-data.noaa_gsod.gsod20*),
--                                    filtered to wban '94728' = NEW YORK CENTRAL PARK
--   * Uploaded NYC zip-code mapping (your_project.cyclistic.zip_codes) for
--                                    borough + neighborhood names
--
-- Output supports:
--   * Course 2 second dashboard page (course2_reports.html / Tableau)
--   * Weather-impact-on-ridership chart
--   * Borough / neighborhood breakdown chart
--   * Subscriber vs casual breakdown with weather as a dimension
--
-- Notes:
--   * Years filtered to 2014-2015 per the course query.
--   * DATE_ADD shifts dates +5 years so the dashboard appears recent
--     (fictional-project convention; remove if you want true historical dates).
--   * Trip durations are bucketed to the nearest 10 minutes via ROUND(.., -1)
--     to reduce row count without losing distribution shape.
--   * Replace YOUR_PROJECT with your GCP project ID. Adjust the
--     cyclistic.zip_codes reference if you uploaded the CSV under a
--     different dataset/table name.

CREATE OR REPLACE TABLE `YOUR_PROJECT.cyclistic_bi.reporting_full_year` AS
SELECT
  TRI.usertype,
  ZIPSTART.zip_code AS zip_code_start,
  ZIPSTARTNAME.borough AS borough_start,
  ZIPSTARTNAME.neighborhood AS neighborhood_start,
  ZIPEND.zip_code AS zip_code_end,
  ZIPENDNAME.borough AS borough_end,
  ZIPENDNAME.neighborhood AS neighborhood_end,
  DATE_ADD(DATE(TRI.starttime), INTERVAL 5 YEAR) AS start_day,
  DATE_ADD(DATE(TRI.stoptime), INTERVAL 5 YEAR) AS stop_day,
  WEA.temp AS day_mean_temperature,
  WEA.wdsp AS day_mean_wind_speed,
  WEA.prcp AS day_total_precipitation,
  ROUND(CAST(TRI.tripduration / 60 AS INT64), -1) AS trip_minutes,
  COUNT(TRI.bikeid) AS trip_count
FROM
  `bigquery-public-data.new_york_citibike.citibike_trips` AS TRI
INNER JOIN
  `bigquery-public-data.geo_us_boundaries.zip_codes` AS ZIPSTART
  ON ST_WITHIN(
    ST_GEOGPOINT(TRI.start_station_longitude, TRI.start_station_latitude),
    ZIPSTART.zip_code_geom)
INNER JOIN
  `bigquery-public-data.geo_us_boundaries.zip_codes` AS ZIPEND
  ON ST_WITHIN(
    ST_GEOGPOINT(TRI.end_station_longitude, TRI.end_station_latitude),
    ZIPEND.zip_code_geom)
INNER JOIN
  `bigquery-public-data.noaa_gsod.gsod20*` AS WEA
  ON PARSE_DATE("%Y%m%d", CONCAT(WEA.year, WEA.mo, WEA.da)) = DATE(TRI.starttime)
INNER JOIN
  `YOUR_PROJECT.cyclistic.zip_codes` AS ZIPSTARTNAME
  ON ZIPSTART.zip_code = CAST(ZIPSTARTNAME.zip AS STRING)
INNER JOIN
  `YOUR_PROJECT.cyclistic.zip_codes` AS ZIPENDNAME
  ON ZIPEND.zip_code = CAST(ZIPENDNAME.zip AS STRING)
WHERE
  WEA.wban = '94728'  -- NEW YORK CENTRAL PARK
  AND EXTRACT(YEAR FROM DATE(TRI.starttime)) BETWEEN 2014 AND 2015
GROUP BY
  1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13;
