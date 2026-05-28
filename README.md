
<img width="1910" height="942" alt="image" src="https://github.com/user-attachments/assets/5427328d-aa54-4370-9d95-6db2a77489e4" />



# Wildfire Monitoring in Germany 

An interactive **R Shiny** dashboard for exploring wildfire activity across Germany between **2020 and 2023**. The app combines NASA satellite fire detections with administrative boundaries to reveal *where*, *when*, and *how intensely* fires have occurred - at both the state (*Bundesland*) and district (*Kreis*) level.

🌐 **Live app:** [reachel.shinyapps.io/Wildfire_Germany](https://reachel.shinyapps.io/Wildfire_Germany/)

---

## Overview

Germany has seen increasing wildfire activity in recent years, driven by drier summers, heatwaves, and changing land-use patterns. This dashboard turns raw satellite fire detections into an explorable, map-based tool, so that:

- Researchers can quickly spot **spatial hotspots** of fire activity.
- Analysts can compare **fire intensity (brightness)** against **detection confidence**.
- Anyone can scrub through time to see **how fire activity evolves day by day**.

---

## Features

- **Interactive point map** - every fire detection plotted by coordinates, colored by confidence class and sized by brightness.
- **Choropleth maps** - fire counts aggregated at the state and district level via spatial joins.
- **Time-series animation** - a date slider lets you replay fire activity across the study period.
- **Statistical filters** - view only points above the mean, median, or one standard deviation of brightness/confidence.
- **Year and confidence filters** - narrow the data down to specific years (2020–2023) or confidence categories (Very Low → Very High).
- **Analysis charts** - interactive `plotly` charts for time series, brightness distribution, and confidence-vs-brightness scatter.
- **Searchable data table** - full record-level view of the filtered dataset, powered by `DT`.

---

## Data Sources

| Dataset | Description | Source |
|---|---|---|
| `Fires_Germany.csv` | Active fire detections (MODIS Collection 6.1) for Germany, 2020–2023. Columns include `acq_date`, `latitude`, `longitude`, `brightness`, `confidence`. | [NASA FIRMS](https://firms.modaps.eosdis.nasa.gov/) - Fire Information for Resource Management System |
| `Germany_Boundary/States.geojson` | Boundaries of the 16 German federal states (*Bundesländer*). | Public German administrative boundary dataset |
| `Germany_Boundary/gadm41_DEU_2.json` | District-level (*Kreis* / Level-2) administrative boundaries for Germany. | [GADM v4.1](https://gadm.org/) |

> **About the fire data:** The MODIS active fire product detects thermal anomalies (hot spots) from NASA's Terra and Aqua satellites. Each row in `Fires_Germany.csv` represents a single pixel where the detection algorithm identified a fire. `brightness` is the brightness temperature of the fire pixel in Kelvin, and `confidence` (0–100) reflects how certain the algorithm is about the detection.

---

## Tech Stack

- **R**
- **Shiny** - web app framework
- **leaflet** - interactive maps
- **sf** - spatial joins between fire points and administrative polygons
- **dplyr**, **lubridate** - data wrangling and date handling
- **ggplot2** + **plotly** - interactive charts
- **DT** - searchable data tables
- **shinyBS** - UI popovers and tooltips

---

## Project Structure

```
Wildfires_Germany/
├── app.R                          # Full Shiny app (UI + server)
├── Fires_Germany.csv              # Fire detection dataset (MODIS, 2020–2023)
├── Germany_Boundary/
│   ├── States.geojson             # State (Bundesland) boundaries
│   └── gadm41_DEU_2.json          # District (Kreis) boundaries
└── README.md
```

---

## Run Locally

1. Clone the repository:
   ```bash
   git clone https://github.com/Reachel97/Wildfires_Germany.git
   cd Wildfires_Germany
   ```
2. Install the required R packages:
   ```r
   install.packages(c("shiny", "leaflet", "DT", "dplyr", "shinyBS",
                      "sf", "ggplot2", "lubridate", "plotly"))
   ```
3. Open `app.R` in RStudio and click **Run App**, or from an R console:
   ```r
   shiny::runApp()
   ```

> The app expects `Fires_Germany.csv` and the `Germany_Boundary/` folder to be in the working directory.

---

## Key Findings

- Wildfire activity is **not evenly distributed** across Germany - detections cluster especially in eastern states (Brandenburg, Saxony, Mecklenburg-Vorpommern), where drier climates and large pine forests create more fire-prone conditions.
- A clear **seasonal signal** is visible in the time-series view: detections concentrate strongly in the summer months.
- Higher-brightness detections tend to come with **higher confidence**, supporting the reliability of the algorithm's stronger signals.
- The district-level choropleth reveals that a small number of *Kreise* contribute a disproportionate share of total detections.

---

## Possible Extensions

- Add **VIIRS** detections (375 m resolution vs MODIS 1 km) for finer spatial detail.
- Overlay **land cover** (e.g. CORINE) to see which biomes burn most.
- Bring in **weather and drought indices** (e.g. ERA5, SPEI) to model fire risk.
- Add a **per-state time-series comparison** panel.
- Deploy as a Docker container for fully reproducible hosting.

---

## Author

**Reachel Sabir** - [@Reachel97](https://github.com/Reachel97)

---

## License & Acknowledgements

Shared for educational and portfolio purposes. Fire detection data courtesy of **NASA FIRMS** under their open data policy. Administrative boundaries from **GADM** (free for non-commercial use).
