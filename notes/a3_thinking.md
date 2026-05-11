# A3 Thinking — Cyclistic Bike-Share

**Goal:** Ensure Cyclistic has sufficient bikes at the right station locations to meet rider demand across New York City.

## 1. Background

Cyclistic operates bike-share across NYC boroughs partnered with the city. Dataset spans 2013–2015 NYC Citi Bike trips plus Census Bureau boundary data for geographic context.

## 2. Current Conditions

Station demand is uneven, bikes get misallocated, no visibility into where supply gaps suppress ridership. A station showing low trips but high nearby population isn't low-demand, it's under-supplied.

## 3. Goals / Targets

- Classify stations into activity tiers using 33rd/66th percentile reference lines (not hard buckets)
- Build a safe zone matrix: send/return balance per station
- Size total fleet need: peak demand plus 30% buffer accounting for bikes in-use and in-maintenance
- Layer population growth data to anticipate demand shifts

## 4. Analysis Questions the Data Must Answer

- Which stations are high/medium/low activity by trip volume?
- What is the send vs return balance per station (drain vs accumulator)?
- How does usage vary by season, year, subscriber vs casual user?
- Where does population growth predict future demand mismatches?

## Dashboard Design Intent

- **Primary view:** 2015 data
- **Secondary:** 2013–2015 trend
- **Map** with checkbox filter (all / high / medium / low stations) showing trip flows as lines, table beside it showing exit/return by station
- **Adjustable buffer parameter** so stakeholders can model fleet size
- **Tertiary:** population shift context layer
