-- 01_station_classification.sql
--
-- Classifies stations into activity tiers (high/medium/low) by station activity
-- using 33rd / 66th percentile reference lines per year (not hard buckets).
--
-- Output supports:
--   * Station tier chart (primary dashboard view)
--   * No-mans list (stations below the 33rd-percentile line)
--   * Send/return balance matrix
--   * Map station markers with checkbox filters by activity tier
--   * Map/table filters for all riders, subscribers, and customers
--
-- Years: 2013-2015 to show trend alongside the 2015 primary view.
-- Dashboard filters: selected_usertype, activity_tier.

WITH station_events AS (
  SELECT
    start_station_id AS station_id,
    start_station_name AS station_name,
    EXTRACT(YEAR FROM starttime) AS trip_year,
    start_station_latitude AS latitude,
    start_station_longitude AS longitude,
    tripduration,
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
    tripduration,
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
station_activity AS (
  SELECT
    station_id,
    ANY_VALUE(station_name) AS station_name,
    trip_year,
    usertype,
    AVG(latitude) AS latitude,
    AVG(longitude) AS longitude,
    ST_GEOGPOINT(AVG(longitude), AVG(latitude)) AS station_geog,
    SUM(departures) AS departures,
    SUM(arrivals) AS arrivals,
    COUNT(*) AS total_station_activity,
    ROUND(AVG(tripduration / 60), 1) AS avg_trip_minutes,
    COUNTIF(usertype = 'Subscriber') AS subscriber_activity,
    COUNTIF(usertype = 'Customer') AS casual_activity,
    SUM(departures) - SUM(arrivals) AS net_departures
  FROM station_events
  GROUP BY GROUPING SETS (
    (station_id, trip_year),
    (station_id, trip_year, usertype)
  )
),
percentiles AS (
  SELECT
    trip_year,
    COALESCE(usertype, 'all') AS selected_usertype,
    APPROX_QUANTILES(total_station_activity, 100)[OFFSET(33)] AS p33,
    APPROX_QUANTILES(total_station_activity, 100)[OFFSET(66)] AS p66
  FROM station_activity
  GROUP BY trip_year, selected_usertype
),
tiered AS (
  SELECT
    s.station_id,
    s.station_name,
    s.trip_year,
    COALESCE(s.usertype, 'all') AS selected_usertype,
    COALESCE(s.usertype, 'all') = 'all' AS includes_all_riders,
    COALESCE(s.usertype, 'all') IN ('all', 'Subscriber') AS includes_subscribers,
    COALESCE(s.usertype, 'all') IN ('all', 'Customer') AS includes_customers,
    s.latitude,
    s.longitude,
    s.station_geog,
    s.departures,
    s.arrivals,
    s.total_station_activity,
    s.avg_trip_minutes,
    s.subscriber_activity,
    s.casual_activity,
    SAFE_DIVIDE(s.subscriber_activity, s.total_station_activity) AS subscriber_activity_share,
    SAFE_DIVIDE(s.casual_activity, s.total_station_activity) AS casual_activity_share,
    s.net_departures,
    CASE
      WHEN s.total_station_activity >= p.p66 THEN 'high'
      WHEN s.total_station_activity >= p.p33 THEN 'medium'
      ELSE 'low'
    END AS activity_tier,
    p.p33,
    p.p66
  FROM station_activity s
  JOIN percentiles p
    ON s.trip_year = p.trip_year
    AND COALESCE(s.usertype, 'all') = p.selected_usertype
),
trended AS (
  SELECT
    *,
    LAG(total_station_activity) OVER(
      PARTITION BY station_id, selected_usertype
      ORDER BY trip_year
    ) AS previous_year_activity,
    LAG(subscriber_activity) OVER(
      PARTITION BY station_id, selected_usertype
      ORDER BY trip_year
    ) AS previous_year_subscriber_activity
  FROM tiered
)
SELECT
  *,
  total_station_activity > previous_year_activity AS is_activity_trending_up,
  subscriber_activity > previous_year_subscriber_activity AS is_subscriber_trending_up
FROM trended
ORDER BY trip_year, selected_usertype, total_station_activity DESC;
