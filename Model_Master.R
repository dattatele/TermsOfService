# Data Mining - Terms of Service
# Master modelling File
library(tm)
library(topicmodels)
library(data.table)
library(kernlab)
library(pROC)
library(stringr)

setwd('~/Git/TermsOfService')

# Read In Data
ToS <- read.csv("Data/TermsOfService_Agreement_Final.csv", header = TRUE, stringsAsFactor = F)
# keep regressor names
regressors <- setdiff(names(ToS),c("Import_HM", "Import_KS", "Import_MH", "Import_JL", 
                             "responseOR", "responseAND","X","Company","ParagraphText"))

response.var = "responseAND"


###################
# Create master corpus

# Create Stopword List
company <- tolower(unique(ToS$Company))
stopwordToS <- c(stopwords("english"),company, "apple", "ibm","wikimedia")

# Generate/Clean Corpus
genCorpusToS <- function(corpusText,stopwordList) {
  corpus = VCorpus(VectorSource(corpusText))
  
  # clean up the corpus
  corpus.clean = tm_map(corpus, stripWhitespace)                          # remove extra whitespace
  corpus.clean = tm_map(corpus.clean, removeNumbers)                      # remove numbers
  corpus.clean = tm_map(corpus.clean, removePunctuation)                  # remove punctuation
  corpus.clean = tm_map(corpus.clean, content_transformer(tolower))       # ignore case
  
  corpus.clean = tm_map(corpus.clean, stemDocument)                       # stem all words
  corpus.clean = tm_map(corpus.clean, removeWords, stopwordList)  # remove stop words
  
  # compute TF-IDF matrix
  DTM <- DocumentTermMatrix(corpus.clean)
  # corpus.clean.tfidf = DocumentTermMatrix(corpus.clean, control = list(weighting = weightTfIdf))
  return(DTM)
}

DTM <- genCorpusToS(ToS$ParagraphText,stopwordToS)


##################################################################
# Functions

# Build LDA
genTopicModelToS <- function(DTM,alpha){
  # train topic model with 50 topics
  if (!missing(alpha)){
    topic.model = LDA(DTM, 50, control = list(alpha = alpha))
  }
  else {
    topic.model = LDA(DTM, 50)
  }
  return(topic.model)
}

# Predict Doc Topic Probabilites
predictLDAToS <- function(topic.model, doc.test) {
  test.topics <- posterior(topic.model,doc.test)
  return(test.topics$topics)
}

# Predict from logistic Model
predictGLMToS <- function(glm.model,test){
  probs <- predict(glm.model, newdata = test, type = "response")
  return(probs)
}

# plot ROC curve
plotROC <- function(probs,response){
    ranks <- order(probs)
    response <- response[ranks]
    probs <- probs[ranks]
    n = length(response)
    positives = sum(response)
    
    precision = numeric(length = n)
    recall = numeric(length = n)
    
    TP = rev(cumsum(rev(response)))
    precision =  TP/(n:1)
    recall =  (TP/positives)
    
    plot(precision, recall, xlim = c(1,0), ylim = c(0,1), xlab = "precision", ylab = "recall", type = 'l')
}


# Calc Error
testErrorToS <- function(probs,response,threshold) {
    preds <- rep(0, length(probs))
    preds[probs > threshold] <- 1
    
    tableToS <- table(c(preds,0,1), c(response,0,1)) - diag(nrow = 2, ncol = 2)
    
    accuracy = sum(diag(tableToS))/sum(tableToS)
    precision = tableToS[2,2]/sum(tableToS[2,])
    recall = tableToS[2,2]/sum(tableToS[,2])
    F1 = precision*recall*2/(precision + recall)
    return(unlist(list(accuracy = accuracy, precision = precision, recall = recall, F1 = F1)))
}



##########################################
# Run Series/Loop

# k companies at a time for testing, n train/test cycles
k = 1;  n = 12

# First set up company list
companies <- unique(ToS$Company)
# every k-tuplet of companies as a row in a matrix
company.list <- t(combn(companies, k))
# random sample of n rows
company.list.sample <- sample(1:nrow(company.list), n)
company.list.sample <- matrix(company.list[company.list.sample,], nrow = n)

predictions <- list()
predictionsLDA <- list()
responses <- list()
responsesLDA <- list()

# For every row in the matrix, generate all test error metrics
testErrors <- apply(company.list.sample, 1, function(companies){
    #testErrorToS(probs= runif(nrow(ToS)),ToS$responseAND,0.7)
    test.indices = which(ToS$Company %in% companies)
    
    # Split
    train.set <- ToS[-test.indices,]
    test.set <- ToS[test.indices,]
    
    # Train LDA
    topic.model <- genTopicModelToS(DTM[-test.indices,])
    predDocTopic <- predictLDAToS(topic.model, DTM[test.indices,])
    
    # Combine Data Sources
    train.set <- cbind(train.set,topic.model@gamma)
    test.set <- cbind(test.set,predDocTopic)
    
    # Modelling
    modelFormula <- as.formula(paste0(response.var,' ~ `', paste0(regressors,collapse = '` + `'), '`'))
    modelFormulaLDA <- as.formula(paste0(response.var,' ~ `', 
                                         paste0(c(regressors,colnames(predDocTopic)),collapse = '` + `'), '`'))
    glm.model <- glm(modelFormula, data = train.set)
    glm.modelLDA <- glm(modelFormulaLDA, data = train.set)
    
    # Tune threshold
    threshold = 
    
    # Prediction
    probs <- predictGLMToS(glm.model,test.set)
    probsLDA <- predictGLMToS(glm.modelLDA,test.set)
    
    # test Error
    testError <- testErrorToS(probs,test.set[[response.var]],0.3)
    testErrorLDA <- testErrorToS(probsLDA,test.set[[response.var]],0.3)
    
    plot.roc(roc(predictor = probs, response = test.set[[response.var]]))
    
    names(testErrorLDA) = paste0(names(testErrorLDA),"LDA")
    
    company.names = paste0(companies, collapse = ".")
    predictions[[company.names]] = probs
    predictionsLDA[[company.names]] = probsLDA
    
    responses[[company.names]] = response
    responsesLDA[[company.names]] = responsesLDA
    
    print(companies)
    print(c(testError, testErrorLDA))
    c(testError, testErrorLDA)
})

# then make them a dataframe for analysis
testErrors <- data.frame(t(testErrors))
rownames(testErrors) = apply(company.list.sample, 1, function(companies) paste0(companies, collapse = "."))
testErrors

write.csv(testErrors, "Data/CompanyTestErrors.csv")

testErrors



##############
# Run models for each rater
response.vars = 


# First set up company list
companies <- unique(ToS$Company)
# every k-tuplet of companies as a row in a matrix
company.list <- t(combn(companies, k))
# random sample of n rows
company.list.sample <- sample(1:nrow(company.list), n)
company.list.sample <- matrix(company.list[company.list.sample,], nrow = n)

predictions <- list()
predictionsLDA <- list()
responses <- list()
responsesLDA <- list()

# For every row in the matrix, generate all test error metrics
testErrors <- apply(company.list.sample, 1, function(companies){
    #testErrorToS(probs= runif(nrow(ToS)),ToS$responseAND,0.7)
    test.indices = which(ToS$Company %in% companies)
    
    # Split
    train.set <- ToS[-test.indices,]
    test.set <- ToS[test.indices,]
    
    # Train LDA
    topic.model <- genTopicModelToS(DTM[-test.indices,])
    predDocTopic <- predictLDAToS(topic.model, DTM[test.indices,])
    
    # Combine Data Sources
    train.set <- cbind(train.set,topic.model@gamma)
    test.set <- cbind(test.set,predDocTopic)
    
    # Modelling
    modelFormula <- as.formula(paste0(response.var,' ~ `', paste0(regressors,collapse = '` + `'), '`'))
    modelFormulaLDA <- as.formula(paste0(response.var,' ~ `', 
                                         paste0(c(regressors,colnames(predDocTopic)),collapse = '` + `'), '`'))
    glm.model <- glm(modelFormula, data = train.set)
    glm.modelLDA <- glm(modelFormulaLDA, data = train.set)
    
    # Tune threshold
    threshold = 
        
        # Prediction
        probs <- predictGLMToS(glm.model,test.set)
    probsLDA <- predictGLMToS(glm.modelLDA,test.set)
    
    # test Error
    testError <- testErrorToS(probs,test.set[[response.var]],0.3)
    testErrorLDA <- testErrorToS(probsLDA,test.set[[response.var]],0.3)
    
    plot.roc(roc(predictor = probs, response = test.set[[response.var]]))
    
    names(testErrorLDA) = paste0(names(testErrorLDA),"LDA")
    
    company.names = paste0(companies, collapse = ".")
    predictions[[company.names]] = probs
    predictionsLDA[[company.names]] = probsLDA
    
    responses[[company.names]] = response
    responsesLDA[[company.names]] = responsesLDA
    
    print(companies)
    print(c(testError, testErrorLDA))
    c(testError, testErrorLDA)
})

# then make them a dataframe for analysis
testErrors <- data.frame(t(testErrors))

################
rownames(testErrors) = apply(company.list.sample, 1, function(companies) paste0(companies, collapse = "."))

testErrors
