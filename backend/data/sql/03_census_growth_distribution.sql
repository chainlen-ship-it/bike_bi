-- 03_census_growth_distribution.sql
--
-- Checks whether ACS population growth is broad across NYC or concentrated
-- enough to be useful as a station-context signal.
--
-- Run this before the station overlay query. If almost every tract is growing,
-- population growth should be treated as background context, not a strong
-- station classifier.

WITH nyc_tracts AS (
  SELECT
    geo_id,
    county_fips_code,
    tract_geom
  FROM `bigquery-public-data.geo_census_tracts.us_census_tracts_national`
  WHERE state_fips_code = '36'
    AND county_fips_code IN ('005', '047', '061', '081', '085')
),
tract_growth AS (
  SELECT
    t.geo_id,
    t.county_fips_code,
    pop_2013.total_pop AS total_pop_2013,
    pop_2015.total_pop AS total_pop_2015,
    pop_2015.total_pop - pop_2013.total_pop AS total_pop_growth,
    SAFE_DIVIDE(pop_2015.total_pop - pop_2013.total_pop, pop_2013.total_pop) AS total_pop_growth_rate
  FROM nyc_tracts t
  JOIN `bigquery-public-data.census_bureau_acs.censustract_2015_5yr` pop_2015
    ON t.geo_id = pop_2015.geo_id
  JOIN `bigquery-public-data.census_bureau_acs.censustract_2013_5yr` pop_2013
    ON t.geo_id = pop_2013.geo_id
  WHERE pop_2013.total_pop > 0
),
growth_thresholds AS (
  SELECT
    APPROX_QUANTILES(total_pop_growth_rate, 100)[OFFSET(33)] AS p33_growth_rate,
    APPROX_QUANTILES(total_pop_growth_rate, 100)[OFFSET(66)] AS p66_growth_rate
  FROM tract_growth
)
SELECT
  tg.geo_id,
  tg.county_fips_code,
  tg.total_pop_2013,
  tg.total_pop_2015,
  tg.total_pop_growth,
  tg.total_pop_growth_rate,
  CASE
    WHEN tg.total_pop_growth_rate >= gt.p66_growth_rate THEN 'high_growth'
    WHEN tg.total_pop_growth_rate >= gt.p33_growth_rate THEN 'medium_growth'
    ELSE 'low_or_declining_growth'
  END AS growth_tier,
  COUNT(*) OVER() AS nyc_tract_count,
  COUNTIF(tg.total_pop_growth > 0) OVER() AS growing_tract_count,
  SAFE_DIVIDE(
    COUNTIF(tg.total_pop_growth > 0) OVER(),
    COUNT(*) OVER()
  ) AS growing_tract_share,
  gt.p33_growth_rate,
  gt.p66_growth_rate
FROM tract_growth tg
CROSS JOIN growth_thresholds gt
ORDER BY total_pop_growth_rate DESC;
