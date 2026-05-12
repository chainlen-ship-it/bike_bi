COURSE 1 · PROJECT PLANNING

**Stakeholder Requirements Document**

*Cyclistic Fleet Intelligence — Google BI Certificate Course 1*

|                      |                                        |
|----------------------|----------------------------------------|
| **BI Professional**  | Chris Hainlen, Groveline LLC           |
| **Client / Sponsor** | Sara Romero, VP Marketing, Cyclistic   |
| **Project**          | Cyclistic Fleet Intelligence Dashboard |
| **Date**             | May 2026                               |

**BUSINESS PROBLEM**

Cyclistic's Customer Growth Team cannot determine whether the fleet is sized correctly or positioned correctly across NYC stations. Low trip counts at a station may reflect low demand — or may simply mean bikes were unavailable when riders arrived. Without the ability to separate those two realities, the team cannot make defensible decisions about where to add stations, how many bikes the system needs, or how to prioritize rebalancing.

The dashboard must answer a question that raw trip data cannot: is this station underperforming because demand is low, or because supply is insufficient?

**STAKEHOLDERS**

|                      |                                                                  |
|----------------------|------------------------------------------------------------------|
| **Sara Romero**      | VP Marketing — primary sponsor, accessibility requirements owner |
| **Ernest Cox**       | VP Product Development — executive viewer, high-level KPIs only  |
| **Jamal Harris**     | Director, Customer Data — data access approvals                  |
| **Nina Locklear**    | Director, Procurement — dashboard viewer                         |
| **Adhira Patel**     | API Strategist — primary technical contact                       |
| **Megan Pirato**     | Data Warehousing Specialist — primary technical contact          |
| **Rick Andersson**   | Manager, Data Governance — primary technical contact             |
| **Tessa Blackwell**  | Data Analyst — primary technical contact, power user             |
| **Brianne Sand**     | Director, IT — dashboard viewer                                  |
| **Shareefah Hakimi** | Project Manager — dashboard viewer                               |

Primary technical contacts: Adhira Patel, Megan Pirato, Rick Andersson, Tessa Blackwell.

**STAKEHOLDER USAGE DETAILS**

Stakeholders will use the dashboard to:

- Monitor fleet sufficiency at peak demand periods, with the ability to adjust the buffer percentage and see the impact on total bikes needed

- Identify which stations are draining inventory (high departures, low returns) vs which are accumulating bikes (low departures, high returns)

- Understand seasonal demand patterns across 2013–2015 to inform annual fleet planning

- Identify latent demand zones — stations in high-population-density areas with low current activity — as candidates for investment

- Compare subscriber and casual customer behavior to understand who is riding and when

Ernest Cox (VP Product Development) requires high-level overviews and will rarely drill into detail. Tessa Blackwell (Data Analytics) explores data in depth and requires full filter controls. The dashboard serves both personas through a dual-view design: executive KPI strip at the top, analyst drill-down below.

**PRIMARY REQUIREMENTS**

- Fleet status indicator showing bikes needed vs available at peak, with live buffer slider (10–50%, default 30%)

- Station activity tier classification using 33rd/66th percentile reference lines — not hard buckets

- Send/return balance per station: drain, accumulator, or balanced classification

- Seasonal trend chart showing 2013–2015 year-over-year overlay with subscriber vs casual split

- Population context layer flagging latent demand zones using Census Bureau data

- Accessibility: large print (minimum 16px), text-to-speech alternatives, WCAG AA color contrast per Sara Romero

- Data privacy: no personal information. All user data anonymized at source. Jamal Harris data access approval required before pipeline runs

- Dashboard viewing access for all ten stakeholders listed above

- Six-week delivery timeline

**SUCCESS CRITERIA**

The dashboard is successful when:

- Sara Romero can determine fleet sufficiency status within three seconds of opening the dashboard

- Ernest Cox can get a complete executive picture without drilling into any detail views

- Tessa Blackwell can filter to any station, year, rider type combination and see the send/return balance and allocated bike count

- The team can identify the top latent demand zone candidates for new station investment

- Fleet sizing decisions can be modeled at multiple buffer percentages without requiring a new query

*Cyclistic Fleet Intelligence Dashboard · Google BI Certificate Portfolio · Chris Hainlen · May 2026*
