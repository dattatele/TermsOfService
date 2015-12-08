# Data Mining - Terms of Service
# Master File

setwd('/Users/hopeemac/Documents/Code/GIT/TermsOfService')

# Read In Data
notRegressors <- 
regs <- setdiff(names(ToS),c("Import_HM", "Import_KS", "Import_MH", "Import_JL", 
                             "responseOR","X","Company","ParagraphText"))

ToS <- read.csv("Data/TermsOfService_Agreement_Final.csv", header = TRUE, stringsAsFactor = F)

# Subset


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

# Run Up to Here
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

# Model


# Predict from Model
predictGLMToS <- function(glm.model,test,threshold){
  probs <- predict(glm.model, test, type = "response")
  return(probs)
}

# Calc Error
testErrorToS <- function(probs,response,threshold) {
  preds <- rep(0, length(probs))
  preds[probs > threshold] <- 1
  tableToS <- table(preds, response)

  accuracy = sum(diag(tableToS))/sum(tableToS)

  precision = tableToS[2,2]/sum(tableToS[2,])
  
  recall = tableToS[2,2]/sum(tableToS[,2])
  
  F1 = precision*recall*2/(precision + recall)
  
  return(list(accuracy = accuracy, precision = precision, recall = recall, F1 = F1))
}

testErrorToS(probs,ToS$responseAND,0.7)

##########################################
# Run Series/Loop

# Split 
# <>

topic.model <- genTopicModelToS(DTM[test.indices,])
predProbs <- predictToS(topic.model, DTM[1:10,])

# Combine Data Sources
train <- cbind(ToS[index,],topic.model@gamma)
test <- cbind(ToS[index,],predProbs)

# MODEL
# <>

probs <- predictGLMToS(glm.model,test,threshold)
testError <- testErrorToS(probs,ToS$responseAND,0.7)