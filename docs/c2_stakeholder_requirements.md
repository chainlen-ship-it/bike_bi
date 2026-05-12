COURSE 2 · DATA PREPARATION

**Stakeholder Requirements Document**

*Cyclistic Fleet Intelligence — Google BI Certificate Course 2*

|                      |                                                       |
|----------------------|-------------------------------------------------------|
| **BI Professional**  | Chris Hainlen, Groveline LLC                          |
| **Client / Sponsor** | Sara Romero, VP Marketing, Cyclistic                  |
| **Project**          | Cyclistic Fleet Intelligence — Data Preparation Stage |
| **Date**             | May 2026                                              |

**STAGE OVERVIEW**

Course 1 produced 9 ad-hoc SQL queries. Course 2 is the data preparation stage: transform those analytical queries into materialized reporting tables that a dashboard and non-engineer stakeholders can use directly. Two new data sources arrive in this stage — daily weather and geographic enrichment — that close gaps identified in the Course 1 planning documents.

**NEW STAKEHOLDER OBSERVATIONS**

Observation of the Cyclistic team in action revealed two distinct user personas that the current single-view design does not serve well:

**Ernest Cox, VP Product Development:** Requests high-level overviews of key performance indicators. Rarely needs detailed drill-downs. Needs a clean executive KPI strip that delivers the answer without requiring interaction.

**Tessa Blackwell, Data Analyst:** Explores data in depth. Spends significant time in dashboard views. Needs full filter controls — year, borough, rider type, weather conditions — and granular data in the drill-down table.

The Course 2 dashboard page is designed to serve both personas from the same data layer. The top of the page is Ernest's view. The bottom is Tessa's.

**NEW REQUIREMENTS FROM COURSE 2**

- Weather impact visualization: scatter chart of daily precipitation vs trip count, colored by year, with split-by-rider-type toggle

- Borough breakdown: bar charts comparing summer ridership and full-year ridership by borough, 2014 vs 2015

- Executive KPI strip: total trips, average trip minutes, peak day, top borough — clean, no drill-down

- Analyst drill-down table: borough, neighborhood, usertype, average temperature, average precipitation, trip count — filterable, sortable, paginated

- Weather assumption label visible in dashboard: precipitation time-of-day not available in NOAA GSOD; any precipitation on a trip day is treated as potentially impacting ridership

**DATA ACCESS AND DEPENDENCIES**

- NOAA GSOD public dataset — no additional approvals required, read-only public BigQuery data

- US zip-code geometry — public BigQuery dataset, read-only

- NYC zip-code CSV — one-time upload to GCP project by BI professional, no stakeholder approval required

- All existing Course 1 data approvals from Jamal Harris remain in effect

*Cyclistic Fleet Intelligence Dashboard · Google BI Certificate Portfolio · Chris Hainlen · May 2026*
