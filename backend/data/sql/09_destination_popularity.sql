-- 09_destination_popularity.sql
-- Destination stations ranked by total trip minutes received
-- A destination is popular not just by trip count but by
-- how long riders traveled to get there
-- Supports: destination popularity table in dashboard
-- Scenario requirement: popular destinations by total trip minutes

SELECT
  end_station_id,
  end_station_name,
  end_station_latitude AS lat,
  end_station_longitude AS lng,
  EXTRACT(YEAR FROM stoptime) AS trip_year,
  CASE
    WHEN EXTRACT(MONTH FROM stoptime) IN (12, 1, 2) THEN 'Winter'
    WHEN EXTRACT(MONTH FROM stoptime) IN (3, 4, 5)  THEN 'Spring'
    WHEN EXTRACT(MONTH FROM stoptime) IN (6, 7, 8)  THEN 'Summer'
    WHEN EXTRACT(MONTH FROM stoptime) IN (9, 10, 11) THEN 'Fall'
  END AS season,
  COUNT(*) AS trips_received,
  ROUND(SUM(tripduration / 60), 0) AS total_trip_minutes,
  ROUND(AVG(tripduration / 60), 1) AS avg_trip_minutes,
  COUNTIF(usertype = 'Subscriber') AS subscriber_arrivals,
  COUNTIF(usertype = 'Customer') AS casual_arrivals
FROM `bigquery-public-data.new_york_citibike.citibike_trips`
WHERE EXTRACT(YEAR FROM stoptime) IN (2013, 2014, 2015)
GROUP BY 1, 2, 3, 4, 5, 6
ORDER BY trip_year, total_trip_minutes DESC
