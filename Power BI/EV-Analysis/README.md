# EV Analysis – Electric Vehicle Sales Dashboard

A Power BI project analyzing global electric vehicle (EV) sales, market trends, and environmental impact.

## Project Overview

This project explores the rapid growth of the electric vehicle market using real-world data.  
The goal was to answer questions such as:

- Which countries sell the most EVs (BEV, PHEV, FCEV)?
- How has EV adoption changed over time?
- What is the environmental impact (oil displacement vs electricity demand)?
- Is it more cost-efficient to own an EV?
- Can the data help identify an ideal next car?

## Dashboard Pages

### 1. Global Sales Statistics
Interactive overview of EV sales by country.  
Key findings:
- China accounts for more than half of global EV sales
- South America has the highest share of PHEVs (~60%)
- South Korea leads in FCEV (hydrogen) sales

### 2. Year-over-Year Growth
Shows sales and market share development over time with YoY comparisons.

### 3. Sales vs Market Share (Scatterplot)
Interactive scatterplot where:
- X-axis = Sales volume
- Y-axis = Sales share (%)
- Bubble size = EV stock

Notable insight: Norway reaches ~93% EV sales share while the USA remains much lower despite higher absolute volume.

### 4. Oil Displacement & Electricity Demand
Analyzes the shift from oil to electricity.  
Data indicates EVs are significantly more energy-efficient (approx. 0.2 kWh/km vs 0.6 kWh/km for petrol cars).

### 5. Fun Stats & Nordic Focus
Summary statistics and a closer look at the rapid electrification in the Nordic countries.

### 6. Find My Dream Car (Bonus)
Scatterplot of EPA range vs price, with additional calculated measures for cost per mile.  
Includes custom categories for price and performance.

## Data Modeling

- Created reference tables for flexible filtering (sales / share / stock)
- Built dimension tables: `Dim_Region`, `Dim_Continent`, `Dim_Powertrain`, `Dim_Date`
- Added calculated columns and a central measures table

## Key Takeaways

- The world is rapidly moving toward electrified transport
- China dominates absolute sales volume
- Norway is a global leader in market share
- EVs appear more cost- and energy-efficient than traditional cars
- The transition is still in an early but accelerating phase

## Files

- `Ev_Cars paul sandegård.pbix` – Power BI report
- `EV-Analysis Paul Sandegård.docx` – Full analysis and reflections (Swedish)
