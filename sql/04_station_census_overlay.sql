-- 04_station_census_overlay.sql
--
-- Adds one-mile Census tract context around each station.
--
-- Use this after station classification to validate whether busy/slow stations
-- line up with nearby population growth. The station logic is repeated here so
-- the query can run as a standalone BigQuery query.
-- Dashboard filters: selected_usertype, activity_tier, station_context_class.

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
    s.subscriber_activity,
    s.casual_activity,
    SAFE_DIVIDE(s.subscriber_activity, s.total_station_activity) AS subscriber_activity_share,
    SAFE_DIVIDE(s.casual_activity, s.total_station_activity) AS casual_activity_share,
    s.net_departures,
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
station_buffers AS (
  SELECT
    *,
    ST_BUFFER(station_geog, 1609.34) AS one_mile_buffer_geog
  FROM station_2015
),
tract_boundaries AS (
  SELECT
    geo_id,
    tract_geom
  FROM `bigquery-public-data.geo_census_tracts.us_census_tracts_national`
  WHERE state_fips_code = '36'
    AND county_fips_code IN ('005', '047', '061', '081', '085')
),
tract_population_growth AS (
  SELECT
    pop_2015.geo_id,
    pop_2013.total_pop AS total_pop_2013,
    pop_2015.total_pop AS total_pop_2015,
    pop_2015.total_pop - pop_2013.total_pop AS total_pop_growth,
    SAFE_DIVIDE(pop_2015.total_pop - pop_2013.total_pop, pop_2013.total_pop) AS total_pop_growth_rate
  FROM `bigquery-public-data.census_bureau_acs.censustract_2015_5yr` pop_2015
  JOIN `bigquery-public-data.census_bureau_acs.censustract_2013_5yr` pop_2013
    ON pop_2015.geo_id = pop_2013.geo_id
),
station_tract_context AS (
  SELECT
    s.station_id,
    s.station_name,
    s.latitude,
    s.longitude,
    s.station_geog,
    s.selected_usertype,
    s.includes_all_riders,
    s.includes_subscribers,
    s.includes_customers,
    s.activity_tier,
    s.total_station_activity,
    s.departures,
    s.arrivals,
    s.net_departures,
    s.is_activity_trending_up,
    s.is_subscriber_trending_up,
    t.geo_id AS tract_geo_id,
    SAFE_DIVIDE(
      ST_AREA(ST_INTERSECTION(s.one_mile_buffer_geog, t.tract_geom)),
      ST_AREA(t.tract_geom)
    ) AS tract_area_weight,
    p.total_pop_2013,
    p.total_pop_2015,
    p.total_pop_growth,
    p.total_pop_growth_rate
  FROM station_buffers s
  JOIN tract_boundaries t
    ON ST_INTERSECTS(s.one_mile_buffer_geog, t.tract_geom)
  LEFT JOIN tract_population_growth p
    ON t.geo_id = p.geo_id
)
SELECT
  station_id,
  station_name,
  latitude,
  longitude,
  ST_GEOGPOINT(longitude, latitude) AS station_geog,
  selected_usertype,
  includes_all_riders,
  includes_subscribers,
  includes_customers,
  activity_tier,
  total_station_activity,
  departures,
  arrivals,
  net_departures,
  is_activity_trending_up,
  is_subscriber_trending_up,
  COUNT(DISTINCT tract_geo_id) AS nearby_tract_count,
  SUM(total_pop_2013 * tract_area_weight) AS nearby_population_2013,
  SUM(total_pop_2015 * tract_area_weight) AS nearby_population_2015,
  SUM(total_pop_growth * tract_area_weight) AS nearby_population_growth,
  SAFE_DIVIDE(
    SUM(total_pop_2015 * tract_area_weight) - SUM(total_pop_2013 * tract_area_weight),
    SUM(total_pop_2013 * tract_area_weight)
  ) AS nearby_population_growth_rate,
  CASE
    WHEN activity_tier = 'high'
      AND is_subscriber_trending_up
      AND SUM(total_pop_growth * tract_area_weight) > 0
      THEN 'validated_busy_growth_zone'
    WHEN activity_tier = 'low'
      AND SUM(total_pop_growth * tract_area_weight) > 0
      THEN 'possible_underserved_growth_zone'
    WHEN activity_tier = 'low'
      AND SUM(total_pop_growth * tract_area_weight) <= 0
      THEN 'validated_slow_zone'
    ELSE 'monitor'
  END AS station_context_class
FROM station_tract_context
GROUP BY
  station_id,
  station_name,
  latitude,
  longitude,
  selected_usertype,
  includes_all_riders,
  includes_subscribers,
  includes_customers,
  activity_tier,
  total_station_activity,
  departures,
  arrivals,
  net_departures,
  is_activity_trending_up,
  is_subscriber_trending_up
ORDER BY total_station_activity DESC;
