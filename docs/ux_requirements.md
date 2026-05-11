# Dashboard UX Requirements
## Cyclistic Fleet Intelligence Dashboard

### Hero Section (Top of Page)
The first thing Sara sees. One number, one decision.

**Fleet Status Indicator**
- Large display: "Bikes Needed: [X]" vs "Current Fleet: [Y]"
- Color state: green (fleet sufficient), yellow (within 10% of gap), 
  red (fleet deficit)
- Buffer slider: 10% to 50%, default 30%, updates hero number live
- Maintenance toggle: adds recommended 5% on top of buffer
- Formula displayed visibly below the number:
  peak_bikes_in_use × (1 + buffer%) = total_fleet_needed

No charts in the hero. Just the number and the control.

---

### Section 2: Station Map
Where the gap lives geographically.

**Map Controls (left sidebar)**
- Year selector: 2013 / 2014 / 2015 (default 2015)
- Activity tier checkboxes: All / High / Medium / Low
- Rider type checkboxes: All / Subscriber / Customer
- Toggle: show trip flow lines (on/off) — spaghetti warning label

**Map Display**
- NYC base map centered on Manhattan
- Station markers sized by trip volume
- Color coded by tier: 
    high = teal, medium = yellow, low = gray, no-mans = red
- Flow lines when toggled on: directional arcs station to station
- Click a station marker: opens detail card (see below)

**Station Detail Card (on click)**
- Station name and ID
- Activity tier badge
- Trips out vs trips in (send/return balance)
- Safe zone status: Balanced / Drain / Accumulator
- Population density within 1 mile (census overlay)
- Allocated bikes at current buffer setting

**Companion Table (right of map)**
- Columns: Station | Tier | Trips Out | Trips In | Balance | 
  Allocated Bikes
- Sorted by: Balance (worst drains at top by default)
- Filtered by: same checkboxes as map (linked)
- Highlight row on map hover, highlight marker on row hover

---

### Section 3: Seasonal Trend
When the gap gets worst.

- Line chart: total trips by season, 2013 / 2014 / 2015 overlaid
- Toggle: split by rider type (subscriber vs casual)
- Reference lines: 33rd and 66th percentile of annual trips
- Annotation: Winter 2015 flagged as weather outlier 
  (polar vortex / Juno blizzard)
- Annotation: 2013 baseline note re Sandy infrastructure aftermath
- Key insight callout box: 
  "Summer peak is [X]% above annual average — 
   fleet sizing should target summer, not annual mean"

---

### Section 4: Population Context
Where demand is heading.

- Map layer toggle (adds to Section 2 map or standalone)
- Census tract shading by population density
- Overlay: stations with low activity but high population density
  flagged as "latent demand" zones
- Callout: mismatch stations listed by name with gap size
- Assumption label visible: 
  "Population data is directional context, not hard evidence.
   Catchment area defined as 1-mile radius from station coordinates."

---

### Accessibility Requirements
Per stakeholder Sara Romero:
- Minimum font size: 16px body, 24px labels, 36px hero numbers
- All charts must have text alternatives (aria-label on SVG elements)
- Color choices must pass WCAG AA contrast ratio
- Tier colors must be distinguishable without color 
  (use shape + color, not color alone)
- Slider must be keyboard navigable

---

### Data Refresh
- Dashboard reads from data/ directory (pre-exported CSVs)
- Run src/extract.py to refresh before opening dashboard.html
- Last refresh date displayed in footer
- No live BigQuery connection required to view dashboard

---

### Design Decisions (resolved)
- **Current fleet size:** derived from max concurrent 
  unique bike IDs in trip data. Understates true fleet 
  (maintenance bikes invisible). Maintenance toggle 
  accounts for this gap.
- **Census catchment:** 1-mile radius from station 
  coordinates confirmed. Labeled as directional 
  assumption in UI.
- **Population layer:** toggle on main map, not 
  separate tab. Correlation must be visible in 
  one view.
- **Weather annotations:** tooltip on hover, 
  not persistent label. Keeps chart clean.
