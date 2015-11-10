#Data Mining Project
#Text mining Terms of Service

#Katherine Schinkel kms6bn
#Hope McIntyre hm7zg
#Matt Hawthorn mah6wt
#Jon Lazenby jsl3xp

#import libraries
library(tm)
library(topicmodels)

#set directory
setwd("~/Git/TermsOfService")

#read terms of use files
fileNames <- paste("Files/", list.files("Files"), sep="")

#function to read file, extract company name, and return company name and terms of service text
read.data = function(data.path){
  #code from http://stackoverflow.com/questions/14639892/how-to-extract-words-between-two-period-using-rs-gsub
  companyName <- strsplit(data.path,'.',fixed=TRUE)[[1]][2]
  termsText <- paste(readLines(data.path), collapse=" ")
  newFile <- data.frame(companyName, termsText)
  return(newFile)
}

#create dataframe with name of company and terms of service as columns
df <- data.frame(Company=character(0), Terms=character(0))
for (i in 1:length(fileNames)){
  newFile <- read.data(fileNames[i])
  df <- rbind(df, newFile)
}

terms <- as.data.frame(df[,2])
terms <-  VCorpus(DataframeSource(terms))

# clean and compute tfidf
terms.clean = tm_map(terms, stripWhitespace)                          # remove extra whitespace
terms.clean = tm_map(terms.clean, removeNumbers)                      # remove numbers
terms.clean = tm_map(terms.clean, removePunctuation)                  # remove punctuation
terms.clean = tm_map(terms.clean, content_transformer(tolower))       # ignore case
terms.clean = tm_map(terms.clean, removeWords, stopwords("english"))  # remove stop words
terms.clean = tm_map(terms.clean, stemDocument)                       # stem all words
terms.clean.tf = DocumentTermMatrix(terms.clean, control = list(weighting = weightTf))

# remove empty documents
row.sums = apply(terms.clean.tf, 1, sum)
terms = terms[row.sums > 0]
terms.clean.tf = terms.clean.tf[row.sums > 0,]

#look at all terms
reviewTerms  <- as.matrix(Terms(terms.clean.tf))

#look at most frequent words
#assistance from https://deltadna.com/blog/text-mining-in-r-for-term-frequency/
frequency <- as.matrix(terms.clean.tf)
frequency <- colSums(frequency)
frequency <- sort(frequency, decreasing=TRUE)
head(frequency, 20)

# train topic model
topic.model = LDA(terms.clean.tf, 8)
terms(topic.model, 10)[,1:8]
