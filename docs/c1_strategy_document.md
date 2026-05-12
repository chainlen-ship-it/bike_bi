COURSE 1 · PROJECT PLANNING

**Strategy Document**

*Cyclistic Fleet Intelligence — Google BI Certificate Course 1*

|                     |                                                    |
|---------------------|----------------------------------------------------|
| **BI Professional** | Chris Hainlen, Groveline LLC                       |
| **Sponsor**         | Sara Romero, VP Marketing                          |
| **Dashboard Tool**  | HTML / Leaflet.js / Chart.js (see rationale below) |
| **Date**            | May 2026                                           |

**PROJECT BACKGROUND**

Cyclistic operates bike-share across NYC boroughs. The Customer Growth Team needs a business intelligence tool that separates two distinct problems that raw trip data conflates: stations that are low-demand and stations that are under-supplied. A station with low trip counts may simply have been out of bikes when riders arrived. Without the ability to make that distinction, fleet and station investment decisions are based on incomplete information.

**DASHBOARD DESIGN — WHY THESE CHOICES**

**Why HTML instead of Tableau:** Tableau was the suggested tool for this course. HTML with Leaflet.js and Chart.js was chosen for three reasons. First, Leaflet is purpose-built for interactive geospatial visualization — the station map with tier-colored markers, directional flow lines, and click-to-detail cards is natural in JavaScript and constrained in Tableau's drag-and-drop environment. Second, building in HTML produces a working prototype for a Next.js or React production frontend. The API calls, endpoints, SQL queries, and data schemas are already figured out. Tableau is a dead end; HTML is a starting point. Third, client-side buffer math — the fleet calculator updating live as the slider moves — is trivial in JavaScript and requires workaround parameter logic in Tableau.

**Why percentile reference lines instead of hard tiers:** Hard tier boundaries create artificial precision. A station at the 34th percentile and one at the 32nd percentile are operationally identical but would fall into different labeled buckets. Reference lines at the 33rd and 66th percentile show the full distribution and let the viewer identify meaningful breaks rather than having those breaks imposed by the data model.

**Why the buffer slider matters:** Fleet sizing is a modeling problem, not a lookup problem. The right buffer percentage depends on maintenance cycles, seasonal peaks, and risk tolerance — all of which change. A live slider that runs peak_bikes_in_use × (1 + buffer%) client-side lets stakeholders model scenarios without requiring a new query or a new dashboard build.

**DASHBOARD VIEWS**

- **View 1:** Hero fleet calculator — bikes needed at peak with live buffer slider, maintenance pool toggle, green/yellow/red fleet status

- **View 2:** Station map — Leaflet NYC map, activity tier and rider type filters, directional flow lines, companion table sorted by drain risk, station detail cards on click

- **View 3:** Seasonal trend — 2013/2014/2015 three-year overlay, subscriber vs casual toggle, percentile reference lines, weather outlier annotations

- **View 4:** Population context — Census tract shading, latent demand zone callouts where low activity meets high population density

**CHART SPECIFICATIONS**

|                    |              |                                 |                                    |                          |
|--------------------|--------------|---------------------------------|------------------------------------|--------------------------|
| **Chart**          | **Type**     | **Dimensions**                  | **Metrics**                        | **Business Question**    |
| Fleet Calculator   | KPI + Slider | —                               | Peak bikes, buffer %, fleet needed | Do we have enough bikes? |
| Station Map        | Geo scatter  | Station, tier, rider type, year | Trip volume, send/return balance   | Where are the gaps?      |
| Seasonal Trend     | Line chart   | Season, year, rider type        | Total trips, % of annual           | When is demand highest?  |
| Population Context | Choropleth   | Census tract, station           | Population density, trip volume    | Where will demand grow?  |

**ACCESSIBILITY**

Per Sara Romero (VP Marketing):

- Minimum font size: 16px body, 24px labels, 36px hero numbers

- All SVG chart elements include aria-label attributes for screen readers

- Color tier coding uses shape plus color — not color alone — to meet WCAG AA contrast requirements

- Buffer slider is keyboard navigable

- No reliance on color alone to convey meaning anywhere in the dashboard

*Cyclistic Fleet Intelligence Dashboard · Google BI Certificate Portfolio · Chris Hainlen · May 2026*
