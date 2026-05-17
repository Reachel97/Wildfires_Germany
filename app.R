library(leaflet)
library(DT)
library(dplyr)
library(shinyBS)
library(shiny)
library(sf)
library(ggplot2)
library(lubridate)
library(plotly)

####PLEASE SET THE PATHS OF THESE THREE FILES TO MAKE THE CODE RUN SUCCESSFULLY########

# Load the wildfire data
wildfire_data <- read.csv("Fires_Germany.csv")

# Load state boundaries data
state_boundaries <- st_read("Germany_Boundary/States.geojson")


# Load district boundaries data
district_boundaries <- st_read("Germany_Boundary/gadm41_DEU_2.json")


# Function to classify confidence levels into six classes

classify_confidence <- function(confidence) {
  if (confidence <= 20) {
    return("Very Low")
  } else if (confidence <= 40) {
    return("Low")
  } else if (confidence <= 60) {
    return("Moderate")
  } else if (confidence <= 80) {
    return("High")
  } else {
    return("Very High")
  }
}

wildfire_data$confidence_class <- sapply(wildfire_data$confidence, classify_confidence)

# Convert acq_date to Date type
wildfire_data$acq_date <- as.Date(wildfire_data$acq_date, format="%Y-%m-%d")

# Load district boundaries data
#district_boundaries <- st_read("C:/Users/Reachel Sabir/Desktop/Wildfire_Germany/Germany_Boundary/gadm41_DEU_2.json")

# Ensure geometries are valid
district_boundaries <- st_make_valid(district_boundaries)

# Convert the fire data to a spatial data frame
fire_data_sf <- st_as_sf(wildfire_data, coords = c("longitude", "latitude"), crs = 4326)

# Perform the spatial join to assign fires to districts
fire_data_with_districts <- st_join(fire_data_sf, district_boundaries, join = st_intersects)

# Aggregate fire counts by district
fire_counts_by_district <- fire_data_with_districts %>%
  group_by(NAME_2) %>%
  summarise(total_fires = n())

# Drop geometry from district boundaries
district_boundaries_df <- district_boundaries %>%
  st_drop_geometry()

# Merge the fire count data with the district boundaries data
merged_data <- merge(district_boundaries_df, fire_counts_by_district, by = "NAME_2", all.x = TRUE)

# Replace NA values in total_fires with 0
merged_data$total_fires[is.na(merged_data$total_fires)] <- 0

# Reassign the geometry
district_boundaries_with_fires <- left_join(district_boundaries, merged_data, by = "NAME_2")

# Load state boundaries data
#state_boundaries <- st_read("C:/Users/Reachel Sabir/Desktop/Wildfire_Germany/Germany_Boundary/States.geojson")

# Ensure geometries are valid
state_boundaries <- st_make_valid(state_boundaries)

# Perform the spatial join to assign fires to states
fire_data_with_states <- st_join(fire_data_sf, state_boundaries, join = st_intersects)

# Aggregate fire counts by state
fire_counts_by_state <- fire_data_with_states %>%
  group_by(GEN) %>%
  summarise(total_fires = n())

# Drop geometry from state boundaries
state_boundaries_df <- state_boundaries %>%
  st_drop_geometry()

# Merge the fire count data with the state boundaries data
merged_state_data <- merge(state_boundaries_df, fire_counts_by_state, by = "GEN", all.x = TRUE)

# Replace NA values in total_fires with 0
merged_state_data$total_fires[is.na(merged_state_data$total_fires)] <- 0

# Reassign the geometry
state_boundaries_with_fires <- left_join(state_boundaries, merged_state_data, by = "GEN")

# Define UI for application
ui <- fluidPage(
  tags$head(tags$title("Wildfire Monitoring in Germany")),
  tags$style(type = "text/css", "
             html, body {width:100%;height:100%;margin:0;padding:0;}
             .leaflet-container {height:100vh;width:100vw;}
             .control-panel {
               position: absolute;
               top: 10px;
               right: 10px;
               z-index: 1000;
               background: white;
               padding: 10px;
               border-radius: 8px;
               box-shadow: 0 2px 4px rgba(0,0,0,0.2);
             }
             .leaflet-control-zoom {
               top: 50px;
               right: 10px;
             }
             .app-title {
               padding: 12px 16px;
               background: white;
               border-bottom: 1px solid #e5e5e5;
               font-size: 22px;
               font-weight: 700;
               color: #1f2937;
             }
             .map-shell { position: relative; }
             .leaflet-container { height: calc(100vh - 56px) !important; }
             .table-panel {
               position: absolute;
               left: 18px;
               right: 18px;
               bottom: 18px;
               z-index: 1100;
               background: rgba(255,255,255,0.98);
               border: 1px solid #dbe2ea;
               border-radius: 10px;
               box-shadow: 0 8px 20px rgba(0,0,0,0.12);
               padding: 8px;
               resize: vertical;
               overflow: auto;
               min-height: 120px;
               max-height: 70vh;
               height: 260px;
             }
             .table-header { display:flex; justify-content:space-between; align-items:center; margin-bottom:6px; font-weight:600; }
             .table-help { font-size:12px; color:#64748b }
             "),
  div(class = "app-title", "Wildfire Monitoring in Germany"),
  tabsetPanel(
    tabPanel("Wildfire Data",
         div(class = "map-shell",
           div(class = "control-panel",
             selectInput("statistic", "Choose a Statistic to View:",
                   choices = c("All Data", "Mean Brightness", "Median Brightness",
                         "SD Brightness", "Mean Confidence", "Median Confidence", "SD Confidence")),
             actionButton("info", "ℹ️", class = "btn-info"),
             bsPopover(id = "info", title = "Statistic Information", content = HTML(
               "Select a statistic to filter the data.<br><br>
         <b>All Data:</b> Show all data points.<br>
         <b>Mean Brightness:</b> Show points with brightness >= mean brightness.<br>
         <b>Median Brightness:</b> Show points with brightness >= median brightness.<br>
         <b>SD Brightness:</b> Show points with brightness >= one SD above mean brightness.<br>
         <b>Mean Confidence:</b> Show points with confidence >= mean confidence.<br>
         <b>Median Confidence:</b> Show points with confidence >= median confidence.<br>
         <b>SD Confidence:</b> Show points with confidence >= one SD above mean confidence."
           ), placement = "right", trigger = "hover"),
             selectInput("year", "Select Year:", choices = c("All", "2020", "2021", "2022", "2023")),
             selectInput("confidence_class", "Select Confidence Class:", choices = c("All", "Very Low", "Low", "Moderate", "High", "Very High"))
           ),
           leafletOutput("wildfireMap"),
           div(class = "table-panel",
             div(class = "table-header",
               span("Fire Records"),
               span(class = "table-help", "Drag the bottom edge to make it taller or shorter")
             ),
             DTOutput("dataTable")
           )
         ),
    ),
    tabPanel("Time Series",
             div(class = "control-panel",
                 selectInput("map_level", "Select Map Level:", choices = c("District Level", "State Level")),
                 sliderInput("selectedDate", "Select Date:",
                             min = min(wildfire_data$acq_date),
                             max = max(wildfire_data$acq_date),
                             value = min(wildfire_data$acq_date),
                             timeFormat = "%Y-%m-%d",
                             animate = animationOptions(interval = 500, loop = FALSE))
             ),
             leafletOutput("districtMap", height = "90vh")
    ),
    tabPanel("Analysis Charts",
             selectInput("chartType", "Select Chart Type:", 
                         choices = c("Time Series", "Distribution", "Confidence vs Brightness")),
             plotlyOutput("analysisChart")
    )
  )
)

# Define server logic
server <- function(input, output, session) {
  filtered_data <- reactive({
    data <- wildfire_data
    if (input$year != "All") {
      data <- data %>% filter(substr(acq_date, 1, 4) == input$year)
    }
    if (input$confidence_class != "All") {
      data <- data %>% filter(confidence_class == input$confidence_class) ## For Statistical Analysis
    }
    if (input$statistic == "Mean Brightness") {
      return(data %>% filter(brightness >= mean(brightness)))
    } else if (input$statistic == "Median Brightness") {
      return(data %>% filter(brightness >= median(brightness)))
    } else if (input$statistic == "SD Brightness") {
      return(data %>% filter(brightness >= sd(brightness)))
    } else if (input$statistic == "Mean Confidence") {
      return(data %>% filter(confidence >= mean(confidence)))
    } else if (input$statistic == "Median Confidence") {
      return(data %>% filter(confidence >= median(confidence)))
    } else if (input$statistic == "SD Confidence") {
      return(data %>% filter(confidence >= sd(confidence)))
    }
    return(data)
  })
  
  output$wildfireMap <- renderLeaflet({
    leaflet() %>%
      setView(lng = 10.0, lat = 51.0, zoom = 6) %>% # Centered on Germany
      addProviderTiles(providers$CartoDB.Positron) %>%
      addCircleMarkers(
        data = filtered_data(),
        ~longitude, ~latitude,
        color = ~case_when( ###Classification on Confidence Class
          confidence_class == "Very Low" ~ "blue",
          confidence_class == "Low" ~ "lightblue",
          confidence_class == "Moderate" ~ "green",
          confidence_class == "High" ~ "orange",
          confidence_class == "Very High" ~ "maroon"
        ),
        radius = ~sqrt(brightness) / 50, ##### adjusts the size of polygons
        label = ~paste("Brightness:", brightness, "<br>",
                       "Confidence:", confidence, "<br>",
                       "Date:", acq_date)
        
      )%>%
      addLegend(
        position = "bottomright",
        colors = c("blue", "lightblue", "green", "orange", "maroon"),
        labels = c("Very Low", "Low", "Moderate", "High", "Very High"),
        title = "Confidence Level"
      )
  })
  
  output$dataTable <- renderDT({
    datatable(filtered_data())
  })
  ###### Classification of the total number of fires on State and District level
  output$districtMap <- renderLeaflet({
    if (input$map_level == "District Level") {
      boundaries <- district_boundaries_with_fires
      bins <- c(0, 1000, 2000, Inf)
      colors <- colorBin(palette = c("#FFE0B2", "orange", "red"), domain = boundaries$total_fires, bins = bins)
    } else {
      boundaries <- state_boundaries_with_fires
      bins <- c(0, 1000, 2000, Inf)
      colors <- colorBin(palette = c("#FFE0B2", "#FFCC80", "#FFB74D"), domain = boundaries$total_fires, bins = bins)
    }
    
    leaflet(boundaries) %>%
      addProviderTiles(providers$CartoDB.Positron) %>%  # Adding grey basemap
      addPolygons(
        fillColor = ~colors(total_fires),
        weight = 1,
        opacity = 1,
        color = "grey",  # Set border color to a lighter orange
        dashArray = "3",
        fillOpacity = 0.7,
        highlightOptions = highlightOptions(
          weight = 2,
          color = "#FFAB40",  # Set highlight border color to a slightly darker orange
          dashArray = "",
          fillOpacity = 0.9,
          bringToFront = TRUE
        ),
        label = ~paste(if (input$map_level == "District Level") NAME_2 else GEN, "<br>", "Total Fires:", total_fires)
      ) %>%
      addLegend(pal = colors, values = ~total_fires, opacity = 0.5, title = NULL,
                position = "bottomright") %>%
      addLegend(
        position = "bottomleft",
        colors = c("blue", "lightblue", "green", "yellow", "red"),
        labels = c("Very Low", "Low", "Moderate", "High", "Very High"),
        title = "Confidence Level"
      )
  })
  observe({
    updateSliderInput(session, "selectedDate",
                      min = min(wildfire_data$acq_date),
                      max = max(wildfire_data$acq_date),
                      value = min(wildfire_data$acq_date))
  })
  
  observe({
    leafletProxy("districtMap") %>%
      clearMarkers() %>%
      addCircleMarkers(
        data = wildfire_data %>% filter(acq_date == input$selectedDate),
        ~longitude, ~latitude,
        color = ~case_when(
          confidence_class == "Very Low" ~ "blue",
          confidence_class == "Low" ~ "lightblue",
          confidence_class == "Moderate" ~ "green",
          confidence_class == "High" ~ "yellow",
          confidence_class == "Very High" ~ "red"
        ),
        radius = ~sqrt(brightness) / 4,
        label = ~paste("Brightness:", brightness, "<br>",
                       "Confidence:", confidence, "<br>",
                       "Date:", acq_date)
      )
  })
  
  output$analysisChart <- renderPlotly({
    data <- filtered_data()
    
    if (input$chartType == "Time Series") {
      p <- ggplot(data, aes(x = acq_date, y = brightness)) +
        geom_line() +
        labs(title = "Brightness over Time", x = "Date", y = "Brightness")
    } else if (input$chartType == "Distribution") {
      p <- ggplot(data, aes(x = brightness)) +
        geom_histogram(binwidth = 10, fill = "blue", color = "white") +
        labs(title = "Brightness Distribution", x = "Brightness", y = "Count")
    } else if (input$chartType == "Confidence vs Brightness") {
      p <- ggplot(data, aes(x = brightness, y = confidence, color = confidence_class)) +
        geom_point() +
        labs(title = "Confidence vs Brightness", x = "Brightness", y = "Confidence")
    }
    
    ggplotly(p)
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
