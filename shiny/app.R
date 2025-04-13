# This script was written by K. Bauer as a scripting test for info fauna job application
# the idea is to write a script to calculate statistics and display data with certain requirements
# no software should be installed at the client PC
#---

#loading libraries
library(sf) #import fgb and other geospatial tasks
library(rnaturalearth) # for map of Switzerland - maybe not necessary
library(shiny)
library(ggplot2)  # For creating pretty plots
library(dplyr)  # For filtering and manipulating data
#library(leaflet) # for making the interactive
#library(crosstalk) # to combine data with html widgets, for plotting data in leaflet
library(rnaturalearth) # for map
library(bslib) # for value box and cards
library(bsicons) # for value box and cards
library(BFS) # other map of CH
library(scales) # to prevent ggplot from using scientific notification on axes


# Loading data 
# reading fgb database
import_fgb <- read_sf("D:/meins/R/InfoFauna/data/CAPT_CHLGE_20250331.fgb") # 2do: adapt path

# create BG map
map_CH <- ne_countries(type = "countries", country = "Switzerland",
                       scale = "medium", returnclass = "sf")
map_CH <- st_transform(map_CH, crs = 2056) #set same crs as data
#or:
switzerland_sf <- bfs_get_base_maps(geom = "suis")
switzerland_sf <- st_transform(switzerland_sf, crs = 2056)



# exploring data
max_altitude <- max(import_fgb$ALTdem)


# ui.R ----
ui <- fluidPage(
  titlePanel("Species Distribution"), # title panel
  textOutput("text1"),
  textOutput("text2"),
  textOutput("text3"),
  

  plotOutput("map", height = 600, width = 850),
#  leafletOutput("map", height = 600, width = 850),
  
  
  sidebarLayout(  # Make the layout a sidebarLayout
    sidebarPanel(
      selectInput(inputId = "SP",  # Give the input a name "Species"
                  label = "Select Species",  # Give the input a label to be displayed in the app
                  choices = unique(import_fgb$SP)), # creates sequence of all occurring species for drop down menu
      br(),
      # filter_checkbox(id = "ALLOC",
      #                 label = "ALLOC",
      #                 sharedData = input,
      #                 group = "ALLOC",
      #                 allLevels = FALSE,
      #                 inline = TRUE,
      #                 columns = 1),
      
      plotOutput("plot_histo_year", height = 200, width = 200),
      br(),
      plotOutput("plot_histo_ALLOC", height = 200, width = 200),
  ),
    
    mainPanel(
      br(),
      plotOutput("plot_elevation"),
      br(),
      plotOutput("plot_year"),
      br(),
    ) 
  )
)

# server.R ----
server <- function(input, output) {
# prints the species name (to be updated with counts, Species ID...)
  output$text1 <- renderText(paste("Selected species: ", input$SP))
  output$text3 <- renderText(paste("Species ID: ",unique(import_fgb[import_fgb$SP==input$SP,]$SPID)))
  output$text2 <- renderText(paste("Number of observations: ", nrow(import_fgb[import_fgb$SP == input$SP,])))


  #Big map with locations
  output$map <- renderPlot(ggplot(import_fgb) +
                             geom_sf(data = switzerland_sf, fill = "skyblue", color = "grey45") + 
                             geom_sf(aes(shape = as.factor(ALLOC), 
                                         color = cut(A, c(0,2009))), 
                                     size = 3,
                                     data = import_fgb[import_fgb$SP == input$SP,],  # Use data from input
                             ) +
                             scale_shape_manual(name = "ALLOC", values = c('0' = 15, '1' = 16, '3' = 18)) + # assigning fixed shapes to the values of ALLOC 
                             scale_color_manual(name = "Year", values = c("snow3", "black"), labels = c("< 2010", ">=2010")) + #not clear where to include 2010...
                             theme_minimal() + 
                             labs(title="Distribution map") +
                             coord_sf(crs = 2056)
                           )
  
#   output$map <- renderLeaflet({ 
#     leaflet() %>% 
#       addWMSTiles(
#         "https://wms.geo.admin.ch/?",
#         layers = 'ch.swisstopo.pixelkarte-grau',
#         options = WMSTileOptions(format = "image/png", transparent = TRUE)) %>%
# #      fitBounds(~min(5), ~min(45), ~max(11), ~max(48)) %>%
#       setView(8.23, 46.82, zoom = 8) %>% # ~ center of Switzerland, good zoom factor
#     addMarkers()
#     #clusterOptions = markerClusterOptions())
#   }) 
  
  output$plot_histo_year <- renderPlot(ggplot(import_fgb, aes(x = A)) +  # Create object called `output$plot` with a ggplot inside it
                              geom_histogram(bins = 50,  # Add a histogram to the plot
                                             fill = "grey",  
                                             data = import_fgb[import_fgb$SP == input$SP,],  # Use data from input
                                             colour = "black") +   # Outline the bins in black
                                 scale_y_continuous(labels = label_comma()) + # to prevent ggplot from using scientific notation
                                 geom_vline(xintercept = 2010,
                                            color="red", 
                                            linetype="dashed", 
                                            linewidth= 1.0) +
                                labs(title="Histogram Year",
                                     x ="Year (A)", y = "Observations (count)")
                              + theme_minimal()
                                )
  
  output$plot_histo_ALLOC<- renderPlot(ggplot(import_fgb, aes(x = ALLOC)) +  # Create object called `output$plot` with a ggplot inside it
                                         geom_histogram(  # Add a histogram to the plot
                                                        fill = "grey",  
                                                        data = import_fgb[import_fgb$SP == input$SP,],  # Use data from input
                                                        colour = "black") +   # Outline the bins in black
                                         labs(title="Histogram ALLOC",
                                              x ="ALLOC (ALLOC)", y = "Observations (count)")
                                       + xlim(c(-0.5, 3.5)) # setting x axis to show all occuring values of ALLOC (0, 1, 3)
                                       + scale_y_continuous(labels = label_comma()) # to prevent ggplot from using scientific notation
                                       + stat_bin(aes(y=after_stat(count), 
                                                      label=ifelse(after_stat(count)==0,"",after_stat(count))), 
                                                  geom ="text", 
                                                  vjust = -0.5, 
                                                  data = import_fgb[import_fgb$SP == input$SP,],)  # Use data from species only
                                       + theme_minimal() +
                                       theme(plot.margin = margin(t = 10, unit = "pt")) + ## pad "t"op region of the plot
                                         coord_cartesian(clip = "off")
  )
  


  output$plot_elevation <- renderPlot(ggplot(import_fgb,aes(x = demrcl)) + 
                                        geom_histogram(aes(y = after_stat(count / sum(count))), 
                                                       breaks = seq(-0.1, max(import_fgb$demrcl, na.rm = TRUE) , 200), # creates the same scale for all subgroups - remove for dynamic scale || -0.1 to avoid wrong binning b/o rounding errors
                                                       binwidth = 200, 
                                                       fill = "grey",  
                                                       data = import_fgb[import_fgb$SP == input$SP,],  # Use data from species only
                                                       colour = "black") +
                                        scale_y_continuous(labels = scales::percent) +
                                        scale_x_continuous(breaks=seq(0,max(import_fgb$demrcl, na.rm = TRUE), 400)) +
                                        labs(title="Distribution of altitude",
                                             x ="Altitude [m] (demrcl)", y = "Percentage") +
                                        coord_flip() +
                                        theme_minimal()
  )
  
  output$plot_year <- renderPlot(ggplot(import_fgb,aes(x = M_2, fill = M_2, colour = 'black')) + 
                                   geom_histogram(data=subset(import_fgb, SP == input$SP & import_fgb$aduAgg == 1 ), 
                                                  aes(x = M_2, 
                                                      fill="Adult", 
                                                      y = after_stat(count / sum(count))),
                                                      binwidth = 1) +
                                   geom_histogram(data=subset(import_fgb, SP == input$SP & import_fgb$juvAgg== 1 ), 
                                                  aes(M_2,
                                                      fill="Juvenile",
                                                      y = - after_stat(count / sum(count))),
                                                  binwidth = 1) +
                                   scale_fill_manual(values = c("grey30", "grey")) +
                                   scale_color_manual(values = c('black', 'black')) +
                                   guides(colour = FALSE) +
                                   scale_x_continuous(breaks=c(1:24),
                                                      labels=c("J", "J", "F", "F","M","M", "A","A", "M","M", "J", "J","J","J","A", "A","S", "S","O", "O","N", "N", "D","D")) +
                                   scale_y_continuous(labels = scales::percent) +
                                   labs(title="Observations of adult and juvenile animals during the year",
                                        fill = "",
                                        color = FALSE,
                                        x = "Half-Month (M_2)", y = "Percentage") +
                                   theme_minimal() +
                                   theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                                         panel.background = element_blank(), axis.line = element_line(colour = "black"))
  )

}

# Run the app ----
shinyApp(ui = ui, server = server)