Project Description
This project presents an interactive Shiny dashboard for analyzing wildfire activity in Germany. It combines fire occurrence data with state and district boundary datasets to visualize where fires are concentrated, how they vary over time, and how fire characteristics such as brightness and confidence are distributed. The app includes an interactive point map, a district/state-level choropleth, a time-based filter, and analysis charts to help users explore wildfire patterns in a spatial and temporal context.

Tools Used
R, Shiny, leaflet, sf, dplyr, ggplot2, plotly, DT, lubridate, and shinyBS replacement logic using Shiny modals.

Data Sources
The analysis uses three local datasets:

Fires_Germany.csv for wildfire observations, including date, latitude, longitude, brightness, and confidence.
States.geojson for German state boundaries.
gadm41_DEU_2.json for German district boundaries.
Key Findings
The dashboard is designed to reveal that wildfire activity is not evenly distributed across Germany and tends to cluster geographically. Fire intensity and confidence can be compared directly on the map, while the district and state summaries highlight which administrative regions contain the highest number of detected fires. The time series and distribution charts help show how wildfire activity changes across dates, and the confidence-versus-brightness view supports checking whether stronger detections also tend to have higher confidence.
