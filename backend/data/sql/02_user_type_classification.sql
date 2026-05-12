-- 02_user_type_classification.sql
--
-- Classifies stations by rider mix so the dashboard can filter and compare
-- subscriber-heavy, customer-heavy, and balanced stations separately from
-- the high/medium/low activity classifier.

WITH station_events AS (
  SELECT
    start_station_id AS station_id,
    start_station_name AS station_name,
    EXTRACT(YEAR FROM starttime) AS trip_year,
    start_station_latitude AS latitude,
    start_station_longitude AS longitude,
    usertype,
    1 AS departures,
    0 AS arrivals
  FROM `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE starttime >= DATETIME('2013-01-01')
    AND starttime < DATETIME('2016-01-01')
    AND start_station_id IS NOT NULL
    AND start_station_latitude IS NOT NULL
    AND start_station_longitude IS NOT NULL

  UNION ALL

  SELECT
    end_station_id AS station_id,
    end_station_name AS station_name,
    EXTRACT(YEAR FROM starttime) AS trip_year,
    end_station_latitude AS latitude,
    end_station_longitude AS longitude,
    usertype,
    0 AS departures,
    1 AS arrivals
  FROM `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE starttime >= DATETIME('2013-01-01')
    AND starttime < DATETIME('2016-01-01')
    AND end_station_id IS NOT NULL
    AND end_station_latitude IS NOT NULL
    AND end_station_longitude IS NOT NULL
),
station_user_mix AS (
  SELECT
    station_id,
    ANY_VALUE(station_name) AS station_name,
    trip_year,
    AVG(latitude) AS latitude,
    AVG(longitude) AS longitude,
    ST_GEOGPOINT(AVG(longitude), AVG(latitude)) AS station_geog,
    COUNT(*) AS total_station_activity,
    COUNTIF(usertype = 'Subscriber') AS subscriber_activity,
    COUNTIF(usertype = 'Customer') AS customer_activity,
    SUM(departures) AS departures,
    SUM(arrivals) AS arrivals
  FROM station_events
  GROUP BY station_id, trip_year
),
trended AS (
  SELECT
    *,
    SAFE_DIVIDE(subscriber_activity, total_station_activity) AS subscriber_activity_share,
    SAFE_DIVIDE(customer_activity, total_station_activity) AS customer_activity_share,
    LAG(subscriber_activity) OVER(
      PARTITION BY station_id
      ORDER BY trip_year
    ) AS previous_year_subscriber_activity,
    LAG(customer_activity) OVER(
      PARTITION BY station_id
      ORDER BY trip_year
    ) AS previous_year_customer_activity
  FROM station_user_mix
)
SELECT
  *,
  CASE
    WHEN subscriber_activity_share >= 0.70 THEN 'subscriber_heavy'
    WHEN customer_activity_share >= 0.40 THEN 'customer_heavy'
    ELSE 'balanced'
  END AS user_type_class,
  subscriber_activity > previous_year_subscriber_activity AS is_subscriber_trending_up,
  customer_activity > previous_year_customer_activity AS is_customer_trending_up
FROM trended
ORDER BY trip_year, total_station_activity DESC;
