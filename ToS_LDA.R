library(XML)
library(tm)
library(topicmodels)

setwd('/Users/hopeemac/Documents/Code/GIT/TermsOfService')
terms <- read.csv('Data/TermsOfService_Agreement_Final.csv', stringsAsFactors = F)

# LDA

corpus = VCorpus(VectorSource(terms$ParagraphText))

# clean up the corpus
corpus.clean = tm_map(corpus, stripWhitespace)                          # remove extra whitespace
corpus.clean = tm_map(corpus.clean, removeNumbers)                      # remove numbers
corpus.clean = tm_map(corpus.clean, removePunctuation)                  # remove punctuation
corpus.clean = tm_map(corpus.clean, content_transformer(tolower))       # ignore case

# Company Names to add to StopWord List
company <- tolower(unique(terms$Company))
corpus.clean = tm_map(corpus.clean, removeWords, c(stopwords("english"),company, "apple"))  # remove stop words

# compute TF-IDF matrix
DTM <- DocumentTermMatrix(corpus.clean)
# corpus.clean.tfidf = DocumentTermMatrix(corpus.clean, control = list(weighting = weightTfIdf))

# remove empty documents
row.sums = apply(DTM, 1, sum)
View(terms[row.sums == 0,])
nrow(DTM[row.sums == 0,])
DTM = DTM[row.sums > 0,]

# train topic model with 50 topics
topic.model = LDA(DTM, 50)

# look at the top 20 words & write to CSV
View(terms(topic.model, 20))
write.table(terms(topic.model,20),"Data/ToS_LDA_Terms.csv", sep = ",")

# Write Topic Probabilities to CSV
write.table(topic.model@gamma,"Data/ToS_LDA_TopicProbs.csv", sep = ",")

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# LDA w/ Stemming Words
corpus = VCorpus(VectorSource(terms$ParagraphText))

# clean up the corpus
corpus.clean = tm_map(corpus, stripWhitespace)                          # remove extra whitespace
corpus.clean = tm_map(corpus.clean, removeNumbers)                      # remove numbers
corpus.clean = tm_map(corpus.clean, removePunctuation)                  # remove punctuation
corpus.clean = tm_map(corpus.clean, content_transformer(tolower))       # ignore case

# Company Names to add to StopWord List
company <- tolower(unique(terms$Company))
corpus.clean = tm_map(corpus.clean, removeWords, c(stopwords("english"),company, "apple", "ibm"))  # remove stop words

corpus.clean = tm_map(corpus.clean, stemDocument)                       # stem all words

# compute TF-IDF matrix
DTM_Stem <- DocumentTermMatrix(corpus.clean)
# corpus.clean.tfidf = DocumentTermMatrix(corpus.clean, control = list(weighting = weightTfIdf))

# remove empty documents
row.sums = apply(DTM_Stem, 1, sum)
nrow(DTM_Stem[row.sums == 0,])
DTM_Stem = DTM_Stem[row.sums > 0,]

# train topic model with 50 topics
topic.model_Stem = LDA(DTM_Stem, 50)

# look at the top 20 words & write to CSV
View(terms(topic.model_Stem, 20))
write.table(terms(topic.model_Stem,20),"Data/ToS_LDA_wStem_Terms.csv", sep = ",")

# Write Topic Probabilities to CSV
write.table(topic.model_Stem@gamma,"Data/ToS_LDA_wStem_TopicProbs.csv", sep = ",")