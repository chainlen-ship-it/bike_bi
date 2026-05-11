-- 05_directional_route_flows.sql
--
-- Builds station-to-station directional flow lines for the map and the table
-- beside it. Direction matters: A -> B and B -> A are separate rows.
--
-- Use route_activity_tier_pair to filter busy-to-busy, busy-to-medium,
-- busy-to-low, and other station-zone movements.
-- Dashboard filters: selected_usertype, route_activity_tier_pair, route_zone_class.

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
    COUNT(*) AS total_station_activity,
    COUNTIF(usertype = 'Subscriber') AS subscriber_activity,
    COUNTIF(usertype = 'Customer') AS casual_activity
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
    s.latitude,
    s.longitude,
    s.station_geog,
    s.total_station_activity,
    s.subscriber_activity,
    s.casual_activity,
    CASE
      WHEN s.total_station_activity >= p.p66 THEN 'high'
      WHEN s.total_station_activity >= p.p33 THEN 'medium'
      ELSE 'low'
    END AS activity_tier
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
),
station_2015 AS (
  SELECT
    *,
    total_station_activity > previous_year_activity AS is_activity_trending_up,
    subscriber_activity > previous_year_subscriber_activity AS is_subscriber_trending_up
  FROM trended
  WHERE trip_year = 2015
),
route_trips AS (
  SELECT
    start_station_id,
    end_station_id,
    'all' AS selected_usertype,
    EXTRACT(DATE FROM starttime) AS trip_date,
    EXTRACT(HOUR FROM starttime) AS start_hour,
    tripduration,
    usertype
  FROM `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE starttime >= DATETIME('2015-01-01')
    AND starttime < DATETIME('2016-01-01')
    AND start_station_id IS NOT NULL
    AND end_station_id IS NOT NULL
    AND start_station_id != end_station_id

  UNION ALL

  SELECT
    start_station_id,
    end_station_id,
    usertype AS selected_usertype,
    EXTRACT(DATE FROM starttime) AS trip_date,
    EXTRACT(HOUR FROM starttime) AS start_hour,
    tripduration,
    usertype
  FROM `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE starttime >= DATETIME('2015-01-01')
    AND starttime < DATETIME('2016-01-01')
    AND start_station_id IS NOT NULL
    AND end_station_id IS NOT NULL
    AND start_station_id != end_station_id
    AND usertype IN ('Subscriber', 'Customer')
),
route_hourly AS (
  SELECT
    start_station_id,
    end_station_id,
    selected_usertype,
    trip_date,
    start_hour,
    COUNT(*) AS trips_in_hour
  FROM route_trips
  GROUP BY start_station_id, end_station_id, selected_usertype, trip_date, start_hour
),
route_summary AS (
  SELECT
    start_station_id,
    end_station_id,
    selected_usertype,
    COUNT(*) AS trips,
    COUNTIF(usertype = 'Subscriber') AS subscriber_trips,
    COUNTIF(usertype = 'Customer') AS casual_trips,
    ROUND(AVG(tripduration / 60), 1) AS avg_trip_minutes,
    APPROX_QUANTILES(tripduration / 60, 100)[OFFSET(50)] AS median_trip_minutes
  FROM route_trips
  GROUP BY start_station_id, end_station_id, selected_usertype
),
route_with_reverse AS (
  SELECT
    route_summary.*,
    COALESCE(reverse_route.trips, 0) AS reverse_trips,
    route_summary.trips - COALESCE(reverse_route.trips, 0) AS net_directional_trips,
    SAFE_DIVIDE(
      route_summary.trips,
      route_summary.trips + COALESCE(reverse_route.trips, 0)
    ) AS directional_trip_share
  FROM route_summary
  LEFT JOIN route_summary reverse_route
    ON route_summary.start_station_id = reverse_route.end_station_id
    AND route_summary.end_station_id = reverse_route.start_station_id
    AND route_summary.selected_usertype = reverse_route.selected_usertype
),
route_peak AS (
  SELECT
    start_station_id,
    end_station_id,
    selected_usertype,
    MAX(trips_in_hour) AS peak_directional_trips_per_hour
  FROM route_hourly
  GROUP BY start_station_id, end_station_id, selected_usertype
)
SELECT
  rs.selected_usertype,
  rs.selected_usertype = 'all' AS includes_all_riders,
  rs.selected_usertype IN ('all', 'Subscriber') AS includes_subscribers,
  rs.selected_usertype IN ('all', 'Customer') AS includes_customers,
  rs.start_station_id,
  origin.station_name AS start_station_name,
  origin.latitude AS start_latitude,
  origin.longitude AS start_longitude,
  origin.station_geog AS start_station_geog,
  origin.activity_tier AS start_activity_tier,
  origin.is_subscriber_trending_up AS start_subscriber_trending_up,
  rs.end_station_id,
  destination.station_name AS end_station_name,
  destination.latitude AS end_latitude,
  destination.longitude AS end_longitude,
  destination.station_geog AS end_station_geog,
  destination.activity_tier AS end_activity_tier,
  destination.is_subscriber_trending_up AS end_subscriber_trending_up,
  CONCAT(origin.activity_tier, '_to_', destination.activity_tier) AS route_activity_tier_pair,
  ST_MAKELINE(origin.station_geog, destination.station_geog) AS route_geog,
  rs.trips,
  rs.reverse_trips,
  rs.net_directional_trips,
  rs.directional_trip_share,
  rs.subscriber_trips,
  rs.casual_trips,
  SAFE_DIVIDE(rs.subscriber_trips, rs.trips) AS subscriber_trip_share,
  SAFE_DIVIDE(rs.casual_trips, rs.trips) AS casual_trip_share,
  rs.avg_trip_minutes,
  rs.median_trip_minutes,
  rp.peak_directional_trips_per_hour,
  CASE
    WHEN origin.activity_tier = 'high'
      AND destination.activity_tier = 'high'
      THEN 'busy_station_zone'
    WHEN origin.activity_tier = 'high'
      AND destination.activity_tier != 'high'
      THEN 'busy_origin_outflow'
    WHEN origin.activity_tier != 'high'
      AND destination.activity_tier = 'high'
      THEN 'busy_destination_inflow'
    ELSE 'other_route'
  END AS route_zone_class
FROM route_with_reverse rs
JOIN route_peak rp
  ON rs.start_station_id = rp.start_station_id
  AND rs.end_station_id = rp.end_station_id
  AND rs.selected_usertype = rp.selected_usertype
JOIN station_2015 origin
  ON rs.start_station_id = origin.station_id
  AND rs.selected_usertype = origin.selected_usertype
JOIN station_2015 destination
  ON rs.end_station_id = destination.station_id
  AND rs.selected_usertype = destination.selected_usertype
ORDER BY trips DESC;
