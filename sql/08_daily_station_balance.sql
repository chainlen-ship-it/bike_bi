-- 08_daily_station_balance.sql
-- Daily net departures per station (departures minus arrivals)
-- Positive = more bikes leaving than arriving (drain risk)
-- Negative = more bikes arriving than leaving (accumulator)
-- Supports: companion table daily congestion view
-- Scenario requirement: daily net starts vs ends per station

WITH daily_departures AS (
  SELECT
    DATE(starttime) AS trip_date,
    start_station_id,
    start_station_name,
    start_station_latitude,
    start_station_longitude,
    COUNT(*) AS departures
  FROM `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) IN (2013, 2014, 2015)
  GROUP BY 1, 2, 3, 4, 5
),
daily_arrivals AS (
  SELECT
    DATE(stoptime) AS trip_date,
    end_station_id,
    COUNT(*) AS arrivals
  FROM `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE EXTRACT(YEAR FROM stoptime) IN (2013, 2014, 2015)
  GROUP BY 1, 2
)
SELECT
  d.trip_date,
  d.start_station_id AS station_id,
  d.start_station_name AS station_name,
  d.start_station_latitude AS lat,
  d.start_station_longitude AS lng,
  d.departures,
  COALESCE(a.arrivals, 0) AS arrivals,
  d.departures - COALESCE(a.arrivals, 0) AS net_departures,
  CASE
    WHEN d.departures - COALESCE(a.arrivals, 0) > 10
      THEN 'Drain'
    WHEN d.departures - COALESCE(a.arrivals, 0) < -10
      THEN 'Accumulator'
    ELSE 'Balanced'
  END AS daily_status
FROM daily_departures d
LEFT JOIN daily_arrivals a
  ON d.start_station_id = a.end_station_id
  AND d.trip_date = a.trip_date
ORDER BY d.trip_date, net_departures DESC
