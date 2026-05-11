-- 06_seasonal_trends.sql
-- Seasonal usage by meteorological season, year, and usertype
-- Supports: year-over-year trend view and weather impact layer
-- Note: weather data lacks time-of-day precision for precipitation.
--   Assumption: any precipitation on a trip day may have impacted ridership.
-- Note: Sandy (Oct 2012) affected station infrastructure into early 2013 --
--   low trip counts at affected stations may reflect supply not demand.
-- Note: Winter 2015 (Jan-Feb) was historically cold with transit shutdowns --
--   expect outlier lows that are weather-driven not demand-driven.

WITH seasonal_trips AS (
  SELECT
    EXTRACT(YEAR FROM starttime) AS trip_year,
    CASE
      WHEN EXTRACT(MONTH FROM starttime) IN (12, 1, 2) THEN 'Winter'
      WHEN EXTRACT(MONTH FROM starttime) IN (3, 4, 5)  THEN 'Spring'
      WHEN EXTRACT(MONTH FROM starttime) IN (6, 7, 8)  THEN 'Summer'
      WHEN EXTRACT(MONTH FROM starttime) IN (9, 10, 11) THEN 'Fall'
    END AS season,
    usertype,
    COUNT(*) AS total_trips,
    ROUND(AVG(tripduration / 60), 1) AS avg_trip_minutes,
    COUNT(DISTINCT bikeid) AS unique_bikes_used,
    COUNT(DISTINCT start_station_id) AS active_stations
  FROM `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) IN (2013, 2014, 2015)
  GROUP BY 1, 2, 3
)
SELECT
  trip_year,
  season,
  usertype,
  total_trips,
  avg_trip_minutes,
  unique_bikes_used,
  active_stations,
  ROUND(100 * total_trips / SUM(total_trips) 
    OVER(PARTITION BY trip_year), 1) AS pct_of_year_trips
FROM seasonal_trips
ORDER BY trip_year, 
  CASE season 
    WHEN 'Winter' THEN 1 
    WHEN 'Spring' THEN 2 
    WHEN 'Summer' THEN 3 
    WHEN 'Fall'   THEN 4 
  END,
  usertype
