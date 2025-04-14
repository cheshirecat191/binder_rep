# This script was written by K. Bauer as a scripting test for a job application at info fauna
# the idea is to write a script to calculate statistics and display data with certain requirements
# no software should be installed at the client PC
#---

#loading libraries
library(sf)         # import fgb and other geospatial tasks
library(BFS)        # for map of Switzerland
library(shiny)      # for shiny app
library(ggplot2)    # for creating pretty plots
library(dplyr)      # for filtering and manipulating data
library(bslib)      # for cards design
library(scales)     # to prevent ggplot from using scientific notification on axes


# Loading data 
# reading fgb database
import_fgb <- read_sf("../data/CAPT_CHLGE_20250331.fgb")
# create BG map from BfS with Swiss coordinate reference system:
switzerland_sf <- bfs_get_base_maps(geom = "suis")
switzerland_sf <- st_transform(switzerland_sf, crs = st_crs(2056))


# shiny user interface
ui <- page_sidebar(
  title = fluidPage(
    titlePanel("Species Distribution"),                          # title panel 
  ),
  
  sidebar =                                                      #extendable sidebar
    sidebar(
      selectInput(inputId = "SP",                                # drop down menu | assigning the ID "SP" to the input 
                  label = "Select Species",                      # assigning a label to the input to be displayed in the app
                  choices = unique(import_fgb$SP)),              # creates list of all occurring species for drop down menu

      plotOutput("plot_histo_year", height = 200, width = 200),  # small histogram here
      br(),
      plotOutput("plot_histo_ALLOC", height = 200, width = 200), # another small histogram here
    )  
  ,
  page_fluid(
    layout_columns(
      card (card_header (
        textOutput("text1"),                        # text outputs to be displayed (species name, count, SPID)
        textOutput("text2"),
        textOutput("text3")
      ),
        plotOutput("map", height = 800)             # large main map
      ),
      card (
        plotOutput("plot_year", height = 600)       # adult and juvenile yearly distribution
      ),
      card(
        plotOutput("plot_elevation" , height = 600) # altitude distribution here | same height as other plot
      ),
      col_widths = c(12, 8, 4)                      # adapting width of the plots
    )
  )
)


# shiny server
server <- function(input, output) {
# defining text outputs for the species name, counts, Species ID...)
  output$text1 <- renderText(paste("Selected species: ", input$SP))
  output$text3 <- renderText(paste("Species ID: ",unique(import_fgb[import_fgb$SP==input$SP,]$SPID)))
  output$text2 <- renderText(paste("Number of observations: ", nrow(import_fgb[import_fgb$SP == input$SP,])))

# defining plot outputs
  #Big map with locations
  output$map <- renderPlot(ggplot(import_fgb) +
                             geom_sf(data = switzerland_sf, fill = "lightcyan1", color = "grey45") # background map
                           + geom_sf(aes(shape = as.factor(ALLOC),                                 # point data with special shape for alloc
                                         color = cut(A, c(-Inf, 2009))), 
                                     size = 3.5,
                                     data = import_fgb[import_fgb$SP == input$SP,])                # Use data from input
                           + scale_shape_manual(name = "Allochtonie", 
                                                values = c('0' = 15, '1' = 16, '3' = 18),          # assigning fixed shapes to the values of ALLOC 
                                                labels = c('0' = 'Autochtone', '1' = 'Allochtone', '3' = 're-introduit'))
                           + scale_color_manual(name = "Year", 
                                                values = c("snow3", "black"),
                                                labels = c("< 2010", ">=2010"))                    # including 2010 in second time interval
                           + theme_minimal()  
                           + labs(title="Distribution map") 
                           + coord_sf(crs = st_crs(2056), datum=st_crs(2056))
                           + theme(text = element_text(size = 15))
                           )
  
  # Histogram with observations per year
  output$plot_histo_year <- renderPlot(ggplot(import_fgb, aes(x = A))                       # Create object called `output$plot` with a ggplot inside it
                                 + geom_histogram(bins = 50,                                # Add a histogram to the plot
                                             fill = "grey",  
                                             data = import_fgb[import_fgb$SP == input$SP,], # Use data from input
                                             colour = "black")                              # outline the bins in black
                                 + scale_y_continuous(labels = label_comma())               # to prevent ggplot from using scientific notation
                                 + geom_vline(xintercept = 2010,                            # horizontal line for year == 2010
                                            color="red", 
                                            linetype="dashed", 
                                            linewidth= 1.0)
                                 + labs(title="Histogram - Year",
                                     x ="Year (A)", y = "Observations (count)")
                                 + theme_minimal()
                                )
  
  #Histogram of values for ALLOC
  output$plot_histo_ALLOC<- renderPlot(ggplot(import_fgb, aes(x = ALLOC))                   # Create object called `output$plot` with a ggplot inside it
                                       + geom_histogram(fill = "grey",                      # Add a histogram to the plot 
                                                        data = import_fgb[import_fgb$SP == input$SP,],  # Use data from input
                                                        colour = "black")                   # Outline the bins in black
                                       + labs(title="Histogram - Allochtonie",
                                              x ="Allochtonie", y = "Observations (count)")
                                       + xlim(c(-0.5, 3.5))                                 # setting x axis to show all occuring values of ALLOC (0, 1, 3)
                                       + scale_y_continuous(labels = label_comma())         # to prevent ggplot from using scientific notation
                                       + stat_bin(aes(y=after_stat(count),                  # displaying count of observations for each value of ALLOC
                                                      label=ifelse(after_stat(count)==0,"",after_stat(count))), 
                                                  geom ="text", 
                                                  vjust = -0.5, 
                                                  data = import_fgb[import_fgb$SP == input$SP,],)  # Use data from species only
                                       + theme_minimal()
                                       + theme(plot.margin = margin(t = 10, unit = "pt"))   # adapting plot margin so counts are displayed completely 
                                       + coord_cartesian(clip = "off")
  )
  

  # Plot of altitude distribution
  output$plot_elevation <- renderPlot(ggplot(import_fgb,aes(x = demrcl))                               # using demrcl, but the same works also with ALTdem
                                        + geom_histogram(aes(y = after_stat(count / sum(count))),      # display percentage on axis
                                                       breaks = seq(-0.1, max(import_fgb$demrcl, na.rm = TRUE) , 200), # creates the same scale for all subgroups - remove for dynamic scale || -0.1 to avoid wrong binning b/o rounding errors
                                                       binwidth = 200, 
                                                       fill = "grey",  
                                                       data = import_fgb[import_fgb$SP == input$SP,],  # Use data from species only
                                                       colour = "black")
                                        + scale_y_continuous(labels = scales::percent)
                                        + scale_x_continuous(breaks = seq(0,max(import_fgb$demrcl, na.rm = TRUE), 400)) # to display axis scale in 400m steps
                                        + labs(title="Distribution of altitude",
                                             x ="Altitude [m] (demrcl)", y = "Percentage")
                                        + coord_flip()                                                 # pivot x and y axis
                                        + theme_minimal()
                                        + theme(text = element_text(size = 20))
  )
  
  # Plot of adult and juvenile animals during the year
  output$plot_year <- renderPlot(ggplot(import_fgb,aes(x = M_2, fill = M_2, colour = 'black'))
                                   + geom_histogram(data=subset(import_fgb, SP == input$SP & import_fgb$aduAgg == 1 ), # subsetting adult animals for selected species
                                                  aes(x = M_2, 
                                                      fill="Adult", 
                                                      y = after_stat(count / sum(count))),                             # display percentage
                                                      binwidth = 1)
                                   + geom_histogram(data=subset(import_fgb, SP == input$SP & import_fgb$juvAgg== 1 ),  # subsetting juvenile animals for selected species
                                                  aes(M_2,
                                                      fill="Juvenile",
                                                      y = - after_stat(count / sum(count))),                           # display percentage
                                                  binwidth = 1)
                                   + scale_fill_manual(values = c("grey30", "grey"))                                   # fill colour
                                   + scale_color_manual(values = c('black', 'black'))                                  # outline colour
                                   + guides(colour = FALSE)                                                            # to remove legend entry for outline colour
                                   + scale_x_continuous(breaks=c(1:24),                                                # assigning scale for half-months
                                                      labels=c("J", "J", "F", "F","M","M", "A","A", "M","M", "J", "J","J","J","A", "A","S", "S","O", "O","N", "N", "D","D"))
                                   + scale_y_continuous(labels = scales::percent)
                                   + labs(title="Observations of adult and juvenile animals during the year",
                                        fill = "",
                                        color = FALSE,
                                        x = "Half-Month (M_2)", y = "Percentage")
                                   + theme_minimal()
                                   + theme(panel.grid.minor = element_blank(),                                         # remove minor grid lines
                                         panel.background = element_blank(), 
                                         axis.line = element_line(colour = "black"),
                                         text = element_text(size = 20)
                                        )
  )
}

# Run the app ----
shinyApp(ui = ui, server = server)