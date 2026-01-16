# Combustion Analysis and Emissions Modeling

## Overview
This MATLAB project analyzes internal combustion engine performance and emissions data. It processes experimental cylinder pressure data and emission scores to calculate heat release rates, thermodynamic properties, and specific emissions.

The model is specifically designed to compare different fuel blends, including:
* **B7** (Standard Diesel)
* **HVO** (Hydrotreated Vegetable Oil)
* **GTL** (Gas-to-Liquid)
* **50/50 Mixtures** (GTL/B7 and HVO/B7)

## Prerequisites
* **MATLAB Version:** R2025b 
* **Required Toolboxes:**
    * DSP System Toolbox
    * Wavelet Toolbox
* **External Data:**
    * NASA Thermodynamic Data (Included in `/Nasa` folder)


## Usage 
Please run the scripts in the following order:

1.  **`ProcessingManualData.m`**
     Purpose: Imports the manually recorded experimental data (Excel) and formats it into MATLAB matrices.
2.  **`HVOAnalysis.m`**
    * Purpose: Performs detailed analysis on the HVO fuel data using the high frequency signal data. It performs pegging, filtering, and Gamma calculations.
3.  **`CompareAllFuels.m`**
    * Purpose: Generates comparison plots for emissions and performance across all tested fuels and injection timings. Also calculates 	       KPIS of every fuel

## File Structure

### Scripts (Run these)
* `ProcessingManualData.m`
* `HVOAnalysis.m` 
* `CompareAllFuels.m` 

### Core Functions
* `AveragePressure.m` - Averages cylinder pressure over recorded cycles.
* `CylinderVolume.m` - Calculates cylinder volume as a function of Crank Angle and engine geometry (defined in the code).
* `Temperature.m` - Calculates cylinder temperature at every crank angle using the Ideal Gas Law.
* `PegPressure.m` - Pegs the averaged cylinder pressure at Intake Valve Closing (IVC) to intake pressure.
* `GammaHVO.m` - Calculates dynamic specific heat ratio ($\gamma$) based on mixture ratios and temperature.

### Combustion & Performance Metrics
* `CalcIMEP.m` - Computes Indicated Mean Effective Pressure (IMEP) for a cycle.
* `IMEP.m` - Alternative calculation based on pressure/volume arrays.
* `CalcIndicatedPower.m` - Computes work per cylinder/cycle and indicated power.
* `CalcHRR.m` - Calculates Apparent Heat Release Rate (AHRR) and Cumulative Heat Release.
* `CalcCA50.m` - Identifies the Crank Angle at 50% Mass Fraction Burned (combustion phasing).

### Emissions Calculations
* `bsfc.m` - Computes Brake Specific Fuel Consumption.
* `bsCO2.m` - Computes Brake Specific CO2 emissions [kg/(W*s)].
* `bsNOx.m` - Computes Brake Specific NOx emissions [kg/(W*s)].
* `GHGintensityperkWh.m` - Calculates Greenhouse Gas intensity per kWh.
* `NOx_massflow_from_fuel.m` - Derives NOx mass flow based on fuel flow and concentration.
* `Massflow.m` - Calculates total mass flow (air + fuel).

### KPI calculation
* `KPIcalculation.m` - Calculates the KPIS for every fuel

### Data Folder
* `EmissionScores/` - Excel files containing manual readings from the AREX meter.
* `Nasa/` - NASA polynomials and thermodynamic functions.
* `*.zip` - Compressed `sdaq` and `fdaq` raw measurement files.

## Authors
[Group 12 4CBLB10 - Sustainable Fuels : Plan A or Plan B?]