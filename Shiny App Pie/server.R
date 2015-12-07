library(shiny)
library(datasets)

# Define server logic required to summarize and view the selected
# dataset
shinyServer(function(input, output) {
  
  setwd('/Users/hopeemac/Documents/Code/GIT/TermsOfService')
  # terms <- read.csv('Data/TermsOfService_Agreement_Final.csv', stringsAsFactors = F)
  terms <- read.csv('Data/Data_App_Testing.csv', stringsAsFactors = F)
  
  
  comp <- unique(terms$Company)
  count = 1
  for (i in comp) {
    assign(i, data.frame(terms[which(terms$Company == i),c("ParagraphText","probs")]))
    count = count +1
  }
  
  # Return the requested dataset
  datasetInput <- reactive({
    switch(input$dataset,
           "Amazon" = Amazon,
           "Cloudant" = Cloudant,
           "Facebook" = Facebook,
           "GitHub" = GitHub,
           "Google" = Google,
           "iCloud" = iCloud,
           "Instagram" = Instagram,
           "Netflix" = Netflix,
           "SoundCloud" = SoundCloud,
           "Twitter" = Twitter,
           "Yahoo" = Yahoo,
           "Youtube" = Youtube)
  })
  
  # Generate a summary of the dataset
  output$summary <- renderPrint({
    dataset <- datasetInput()
    summary(dataset)
  })
  
  # Show the first "n" observations
  output$view <- renderTable({
    # print(input$slider1)
    dataset_probs <- datasetInput()
    # dataset_probs <- dataset_probs[which(dataset_probs$probs >= input$slider1),]
    print(nrow(dataset_probs[which(dataset_probs$probs >= input$slider1),]))
    dataset_probs[which(dataset_probs$probs >= input$slider1),]
    #head(dataset_probs, n = input$obs)
  })
  
  output$plot = renderPlot({
    dataset_probs <- datasetInput()
    A <- nrow(dataset_probs[which(dataset_probs$probs >= input$slider1),])
    B <- nrow(dataset_probs) - A
    piePlotData = c(A,B)
    # piePlotData = aggregate(. ~ Gender, datasetInput(), sum)
    # pie(piePlotData[[input$pieData]], labels = piePlotData[[input$pieGroups]])
    pie(piePlotData, labels = c("Important","Unimportant"))
  })
})