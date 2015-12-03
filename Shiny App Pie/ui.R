library(shiny)

# Define UI for dataset viewer application
shinyUI(fluidPage(
  
  # Application title
  titlePanel("Terms of Service - Key Paragraph Predictor"),
  
  # Sidebar with controls to select a dataset and specify the
  # number of observations to view
  sidebarLayout(
    sidebarPanel(
      selectInput("dataset", "Choose a Terms of Service:", 
                  choices = c("Amazon",
                              "Cloudant",
                              "Facebook",
                              "GitHub",
                              "Google",
                              "iCloud",
                              "Instagram",
                              "Netflix",
                              "SoundCloud",
                              "Twitter",
                              "Yahoo",
                              "Youtube")),
      
      sliderInput("slider1", "Select a Probabilty of Importance to view:",
                  min = 0, max = 1, value = 0, step = 0.1),
      plotOutput("plot")
    ),
    
    # Show a summary of the dataset and an HTML table with the 
    # requested number of observations
    mainPanel(
      tableOutput("view")
    )
  )
))