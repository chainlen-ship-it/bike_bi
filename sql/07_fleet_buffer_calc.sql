-- 07_fleet_buffer_calc.sql
-- PURPOSE: Calculate peak concurrent bike usage by season and year.
-- This is the foundation of the buffer calculator on the dashboard.
--
-- LOGIC:
--   A bike is "in use" from starttime to stoptime.
--   Peak concurrent trips = maximum number of overlapping trips 
--   at any moment during the period.
--   We approximate this by counting trips active at each hour bucket.
--
-- BUFFER FORMULA (applied in dashboard, not SQL):
--   total_fleet_needed = peak_concurrent_trips * (1 + buffer_pct)
--   buffer_pct is adjustable by stakeholder in the dashboard (default 30%)
--
-- STATION DISTRIBUTION:
--   Each station's share = (station_trips / total_trips) * total_fleet_needed
--   This tells you how many bikes each station should hold at peak.
--
-- ASSUMPTION: 
--   Bikes in maintenance are not captured in trip data.
--   Recommend adding 5% on top of buffer for maintenance pool.

WITH hourly_trips AS (
  SELECT
    EXTRACT(YEAR FROM starttime) AS trip_year,
    CASE
      WHEN EXTRACT(MONTH FROM starttime) IN (12, 1, 2) THEN 'Winter'
      WHEN EXTRACT(MONTH FROM starttime) IN (3, 4, 5)  THEN 'Spring'
      WHEN EXTRACT(MONTH FROM starttime) IN (6, 7, 8)  THEN 'Summer'
      WHEN EXTRACT(MONTH FROM starttime) IN (9, 10, 11) THEN 'Fall'
    END AS season,
    DATETIME_TRUNC(starttime, HOUR) AS hour_bucket,
    COUNT(*) AS trips_starting,
    COUNT(DISTINCT bikeid) AS unique_bikes_active
  FROM `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) IN (2013, 2014, 2015)
  GROUP BY 1, 2, 3
),
peak_by_season AS (
  SELECT
    trip_year,
    season,
    MAX(unique_bikes_active) AS peak_bikes_in_use,
    MAX(trips_starting) AS peak_trips_in_hour,
    ROUND(AVG(unique_bikes_active), 0) AS avg_bikes_in_use
  FROM hourly_trips
  GROUP BY 1, 2
)
SELECT
  trip_year,
  season,
  peak_bikes_in_use,
  peak_trips_in_hour,
  avg_bikes_in_use,
  ROUND(peak_bikes_in_use * 1.30, 0) AS fleet_needed_30pct_buffer,
  ROUND(peak_bikes_in_use * 1.35, 0) AS fleet_needed_35pct_buffer,
  ROUND(peak_bikes_in_use * 1.40, 0) AS fleet_needed_40pct_buffer
FROM peak_by_season
ORDER BY trip_year,
  CASE season
    WHEN 'Winter' THEN 1
    WHEN 'Spring' THEN 2
    WHEN 'Summer' THEN 3
    WHEN 'Fall' THEN 4
  END;

-- NOTE FOR DASHBOARD:
-- The three buffer columns (30/35/40) are static previews only.
-- The live buffer slider in the dashboard replaces these with:
--   peak_bikes_in_use * (1 + [user_selected_buffer])
-- Export this query result to your dashboard data source.
-- The slider then does the math client-side, no re-query needed.