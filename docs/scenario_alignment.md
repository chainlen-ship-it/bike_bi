# Scenario Alignment

This checklist maps the current Cyclistic BI project work back to the Google BI
Cyclistic workplace scenario goals.

## Covered Well

- Starting and ending station analysis: covered by station classification, daily balance, and route flow queries.
- High/medium/low station activity levels: covered by `sql/01_station_classification.sql`.
- Subscribers vs non-subscribers: covered by `sql/02_user_type_classification.sql` and dashboard filter fields.
- Map/table visualization by station location: covered in `docs/ux_requirements.md`.
- Directional flow between stations: covered by `sql/05_directional_route_flows.sql`.
- Congestion / imbalance: covered by departures, arrivals, net departures, directional imbalance, and daily station balance.
- Seasonality across multiple years: covered by `sql/06_seasonal_trends.sql`.
- Fleet and bike availability concern: covered by `sql/07_fleet_buffer_calc.sql` and the dashboard buffer slider.
- Destination popularity by total trip minutes: covered by `sql/09_destination_popularity.sql`.
- Daily net starts vs ends per station: covered by `sql/08_daily_station_balance.sql`.
- Accessibility requirement from Sara Romero: covered in `docs/ux_requirements.md`.
- Privacy: current queries do not use personal names, emails, phone numbers, or addresses.

## Gaps To Address Later

- Summer 2015 focus: add a dedicated dashboard view/filter or callout for summer 2015.
- Weather impact: dashboard currently plans annotations, but no weather dataset is joined yet.
- Geographic aggregation names: Census tract overlay exists, but borough/neighborhood labels would improve readability.
- Population density: station overlay currently emphasizes population growth; add density fields if the station detail card keeps that wording.
- Dashboard data wiring: `src/extract.py` is implemented, but `dashboard.html` still needs to read the exported CSVs.
- Executive summary: still needs the final one-page narrative and key metrics once dashboard outputs are stable.

## Readiness

The project is ready to build the first UX overlay. Remaining gaps are additive
and can be handled after the first dashboard pass.
