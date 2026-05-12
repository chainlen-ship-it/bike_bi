COURSE 2 · DATA PREPARATION

**Planning Document**

*Cyclistic Fleet Intelligence — Google BI Certificate Course 2*

|                     |                              |
|---------------------|------------------------------|
| **BI Professional** | Chris Hainlen, Groveline LLC |
| **Project Manager** | Shareefah Hakimi             |
| **Stage**           | Data Preparation             |
| **Date**            | May 2026                     |

**DELIVERABLES CHECKLIST**

|                                         |            |                                                  |
|-----------------------------------------|------------|--------------------------------------------------|
| **Deliverable**                         | **Status** | **Location**                                     |
| Course 2 A3 framing                     | Complete   | [docs/c2_a3.md](c2_a3.md)                       |
| Stakeholder Requirements Document       | Complete   | [docs/c2_stakeholder_requirements.md](c2_stakeholder_requirements.md) |
| Project Requirements Document           | Complete   | [docs/c2_project_requirements.md](c2_project_requirements.md) |
| Strategy Document                       | Complete   | [docs/c2_strategy_document.md](c2_strategy_document.md) |
| NYC zip code CSV uploaded to BigQuery   | Complete   | YOUR_PROJECT.cyclistic.zip_codes                 |
| reporting_full_year target table        | Complete   | backend/data/sql/10_reporting_table_full_year.sql |
| reporting_summer target table           | Complete   | backend/data/sql/11_reporting_table_summer.sql   |
| course2_reports.html dashboard page     | Complete   | frontend/source/course2_reports.html             |
| Dual-persona view (executive + analyst) | Complete   | frontend/source/course2_reports.html             |
| extract.py CSV export pipeline          | Complete   | backend/app/src/extract.py                       |

**KEY DESIGN DECISIONS**

**ELT over ETL:** BigQuery handles transformation in-warehouse. No reason to transform before landing data in a system designed for that work.

**Two tables over one filtered table:** Summer queries run independently and frequently. Separate materialization avoids full-year scans for summer-only views.

**10-minute duration buckets:** Reduces row count while preserving distribution shape. Sub-10-minute duration granularity is not required by any stakeholder request.

**Central Park as weather proxy:** Single weather station simplifies the join without materially reducing insight quality. Limitation documented in dashboard.

**DATE_ADD +5 years:** Fictional-project convention to make dates appear recent. Removable for true historical analysis.

**OPEN ITEMS**

- Keep `.env` updated with the active Google Cloud project before refreshing CSV exports.

- Borough label null coverage — stations outside uploaded zip code CSV show null labels. Acceptable for portfolio purposes.

- Loom walkthrough video — planned, demonstrates weather scatter and dual-persona view

*Cyclistic Fleet Intelligence Dashboard · Google BI Certificate Portfolio · Chris Hainlen · May 2026*
