
# --> Question is, Could this be Simpler?

#===============================================================================

# Housekeeping
#===============================================================================

# Libraries
library(tidyverse)
library(shiny)
library(shinydashboard)
library(plotly)

#===============================================================================

# Data Management
#===============================================================================

# Prep data from starting data frame containing all time segments
# data <- readRDS("output/grotto_app_data_bars.rds")
# 
# # Get available options from the data frame
# date_range_var <- unique(data$date_range)

data <- mtcars
date_range_var <- 1:8

#===============================================================================

# Layout
#===============================================================================

#Shiny ui dashboard
header <- dashboardHeader(
  title = "ONC BARS Raw Data Viewer",
  titleWidth = 970
  
  # Make this just show text, Logo, and full company name, 
  # either remove link or make it point to something 
  # tags$li(a(href = 'https://www.integral-corp.com',
  #           img(src = 'Integral_logo_no consulting.png',
  #               tags$style(".main-header {max-height: 150px}"),
  #               title = "Integral Website", height = "40px", width = "100px"),
  #           style = "padding-top:5px; padding-bottom:5px;"),
  #         class = "dropdown")
  
) #header


# Sidebar (where most of the inputs will be for reactive expressions)
side <- dashboardSidebar(
  width = 140,
  sidebarMenu(
    
    # This app will be a single tab, for multiple tabs
    menuItem("Data Viewer", tabName = "data", icon = icon("life-ring")),
    
    br(),
    br(),
    
    # Data segment selection options - radio buttons
    radioButtons(inputId = "data_segment", 
                 label = "Data Segments",
                 choices = date_range_var,
                 selected = date_range_var[8])
    
    # resample - slider
    
    # time bounds - text entry
    
    # window size - dual slider
    # --> Will have to change the time bound code in the reactive expression
    #     a bit to accommodate 2 inputs
    
  )) #sidebar

  

  

# Main Plot Panel
body <- dashboardBody(
  
  # Format the header
  tags$head(
    tags$style(
      HTML('.main-header .logo {
               font-family: "Georgia", Times,
                            "Times New Roman", serif;
               font-weight: bold;
               font-size: 32px;
            }')
    )
  ),
  
  # tabItems
  tabItems(
    tabItem(tabName = "data",
            fluidRow(
              
              # --> could also consider a static map column just to show 
              #     instrumentlocation
              
              column(
                
                width = 12,
                box(width = NULL, 
                    solidHeader = T,
                    # --> put plot output here, need to know type and name
                    #     of output
                    plotlyOutput("four_panel_ts")
                    ),
                
                # --> add another element to the column, e.g., tabBox, infoBox
                # --> This will need to point to a text output in the server
                #     function, so will need to know the type and name of
                #     the output 
                box(width = NULL,
                    textOutput("data_summary_msg"))
                
              ) # end column
            ) # end fluidRow
    ) # end data tab
  ) # end all tabItems
) #end body

# Combine layout components
ui <- dashboardPage(
  header,
  side,
  body
)

#===============================================================================

# Interactivity
#===============================================================================

# server (host reactive expressions)
server <- function(input, output) {
  
  # reactive expression for data filtered in different ways
  # name is used to reference these results 
  ts_get <- reactive({
    
    cd <- input$data_segment
    
    # export filtered data
    return(cd)
    
  })
  
  # Time series four panel plot
  output$four_panel_ts <- renderPlotly({
    
    # --> Create plot using updated data frame, ts_get
    # fig <- iris %>%
    #   group_by(Species) %>%
    #   do(p=plot_ly(., x = ~Sepal.Length, y = ~Sepal.Width, 
    #                color = ~Species, type = "scatter", mode = "markers")) %>%
    #   subplot(nrows = 1, shareX = TRUE, shareY = TRUE)
    # 
    fig <- readRDS("output/voltage_temp_time_series.rds")
    
    return(fig)
    
  })
  
  output$data_summary_msg <- renderText({
    
    print(paste0("selection: ", ts_get()))
    
  })
  
}
  

# Final Build
#===============================================================================
shinyApp(ui = ui, server = server)

#===============================================================================
