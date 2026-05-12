COURSE 1 · PROJECT PLANNING

**Project Requirements Document**

*Cyclistic Fleet Intelligence — Google BI Certificate Course 1*

|                     |                              |
|---------------------|------------------------------|
| **BI Professional** | Chris Hainlen, Groveline LLC |
| **Project Manager** | Shareefah Hakimi             |
| **Sponsor**         | Sara Romero, VP Marketing    |
| **Date**            | May 2026                     |

**PROJECT GOAL**

Grow Cyclistic's customer base by ensuring the right number of bikes are available at the right station locations to meet rider demand across NYC. The dashboard provides the fleet intelligence layer that makes that goal measurable and actionable.

**DATASETS**

- Primary: NYC Citi Bike Trips 2013–2015 (bigquery-public-data.new_york_citibike.citibike_trips) — every trip start/end station, time, bike ID, and rider type

- Secondary: US Census Bureau boundaries (bigquery-public-data.geo_census_tracts + census_bureau_acs) — population context for latent demand analysis

- Course 2 additions: NOAA GSOD daily weather and US zip-code geometry for geographic enrichment

Data privacy: dataset must not include personal information (name, email, phone, address). Users are anonymized. Jamal Harris (Director, Customer Data) must approve data access before pipeline runs.

**DELIVERABLES AND METRICS**

- Station activity classification by trip volume using 33rd/66th percentile reference lines, 2013–2015

- Send/return balance per station per day — drain, accumulator, or balanced classification

- Fleet buffer calculator: peak concurrent bikes × (1 + buffer%) = total fleet needed

- Seasonal trend chart: trips by season, year, and rider type with percentile reference lines

- Destination popularity ranked by total trip minutes (not just trip count)

- Population overlay: Census tract shading with latent demand zone callouts

- Interactive NYC map with activity tier filters, directional flow lines, station detail cards

|                     |                                     |                        |
|---------------------|-------------------------------------|------------------------|
| **Metric**          | **Definition**                      | **Dashboard Location** |
| Fleet needed        | Peak bikes in use × (1 + buffer%)   | Hero section           |
| Fleet status        | Green/yellow/red vs current fleet   | Hero section           |
| Station tier        | 33rd/66th percentile of trip volume | Map + companion table  |
| Send/return balance | Departures minus arrivals per day   | Companion table        |
| Latent demand       | Low trips + high population density | Population layer       |
| Summer peak %       | Summer trips as % of annual total   | Seasonal chart         |

**SIX-WEEK ROLLOUT PLAN**

|           |                                   |                                                                                       |
|-----------|-----------------------------------|---------------------------------------------------------------------------------------|
| **Week**  | **Milestone**                     | **Details**                                                                           |
| Week 1    | Dataset assigned                  | Validate fields and BikeIDs, confirm data access approvals with Jamal Harris          |
| Weeks 2–3 | SQL and ETL development           | Station classification, seasonal trends, fleet buffer, route flows, census overlay    |
| Weeks 3–4 | Dashboard design                  | UX requirements, wireframe mockup, first draft review with Adhira, Megan, Rick, Tessa |
| Weeks 5–6 | Dashboard development and testing | HTML dashboard build, extract pipeline, accessibility review, final delivery to Sara  |

**SUCCESS CRITERIA**

- Leadership can identify fleet sufficiency status and top drain stations within 60 seconds of opening the dashboard

- The team can model fleet sizing at multiple buffer percentages without requiring a new query

- Latent demand zones are identified and ranked for potential new station investment

- Dashboard meets Sara Romero accessibility requirements: 16px minimum font, text-to-speech support, WCAG AA contrast

*Cyclistic Fleet Intelligence Dashboard · Google BI Certificate Portfolio · Chris Hainlen · May 2026*
