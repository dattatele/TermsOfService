library(XML)
library(tm)
library(topicmodels)
library(SnowballC)
install.packages("Rcmdr")
library(Rcmdr)        # for the stepwise function

setwd("/Users/jsl3xp/Documents/Data Science/SYS 6018")

# read data:
set.seed(1)
tos.df <- read.csv("ToS_updated.csv", header = TRUE)
names(tos.df)
extra.columns <- c("Import_HM", "Import_KS", "Import_MH", "Import_JL", "responseOR")
tos.df <- tos.df[, !(names(tos.df) %in% extra.columns)]
names(tos.df)[length(tos.df)] <- "Response"
names(tos.df)

# remove rows with missing values
na.find <- function(x) {sum(is.na(x))} 
tos.df$na.count <- apply(tos.df, 1, na.find)
missing.rows <- which(tos.df$na.count > 0)       # indices for those rows
tos.df <- tos.df[-missing.rows, ]
sum(apply(tos.df, 1, na.find))                   # double check that no missing values are left
tos.df <- tos.df[, -17]

lapply(tos.df, class)

# convert variables to appropriate formats
tos.df$CapsCount <- as.integer(tos.df$CapsCount)
tos.df$CapToLegthRatio <- as.integer(tos.df$CapToLegthRatio)
tos.df$ParaLocation <- as.numeric(tos.df$ParaLocation)
tos.df$Parentheses <- as.integer(tos.df$Parentheses)
tos.df$AvgWordLength <- as.numeric(tos.df$AvgWordLength)

lapply(tos.df, class)                           

#######################################################################################################################

### REGRESSION MODELING ###

names(tos.df)
df.noText <- tos.df[, -c(1, 2)]
names(df.noText)

s <- sample(1:nrow(df.noText), .5*(nrow(df.noText)), replace = FALSE)
train <- df.noText[s, ]
test <- df.noText[-s, ]

# Logistic Regression (WITHOUT Topic Modeling) #

# Full Model:
model.full <- glm(Response ~ ., data = train, family = "binomial") 
summary(model.full)
probs <- predict(model.full, test, type = "response")
length(probs)
preds <- rep(0, nrow(test))
preds[probs > .5] <- 1
table(preds, test$Response)
(411+3)/(411+3+10+75)
# ~ 82.9%

# Perform Stepwise Regression
stepwise(model.full, 
         direction = c("backward/forward"), 
         criterion = c("AIC"))
names(tos.df)
model.reduced <- glm(Response ~ SpacesCount + CapsCount + CapToLegthRatio + Waiver
                     + ParagraphWords + Quotes + AvgWordLength, data = train, 
                     family = "binomial")
# got rid of: ParagraphLength, ParaLocation, Arbitration, ThirdParty, ParagraphSentences, Parentheses
summary(model.reduced)
probs <- predict(model.reduced, test, type = "response")
pred <- rep(0, nrow(test))
pred[probs > .5] <- 1
table(preds, test$Response)
# same result



#######################################################################################################################

### Topic Modeling ###

# create the corpus to be used for topic modeling
tos.text <- as.data.frame(tos.df$ParagraphText)
tos.corpus <- VCorpus(DataframeSource(tos.text))

# clean and compute tfidf:
tos.clean <- tm_map(tos.corpus, stripWhitespace)
tos.clean <- tm_map(tos.clean, removeNumbers)
tos.clean <- tm_map(tos.clean, removePunctuation)
tos.clean <- tm_map(tos.clean, content_transformer(tolower))
tos.clean <- tm_map(tos.clean, removeWords, stopwords("english"))
companies <- c("yahoo", "google", "github", "wikipedia", "amazon", "soundcloud", "twitter", "cloudant", 
               "instagram", "netflix", "facebook", "youtube", "icloud")
tos.clean <- tm_map(tos.clean, removeWords, companies)
tos.clean <- tm_map(tos.clean, removeWords, filler.words)
tos.clean <- tm_map(tos.clean, stemDocument)
doc.term.matrix <- DocumentTermMatrix(tos.clean, control = list(weighting = weightTf))

# Remove Empty Documents:
row.sums <- apply(doc.term.matrix, 1, sum) 
removed.documents <- which(row.sums == 0)
tos.corpus <- tos.corpus[row.sums > 0]

doc.term.matrix <- doc.term.matrix[row.sums > 0,]
doc.term.matrix

# Topic model with 10 topics:
tm.10 <- LDA(doc.term.matrix, 10)     # train model with 10 topics
terms(tm.10,10)            # look at top 10 words
topics(tm.10, 5)[, 1:5]
topics(tm.10, 1)    



# group documents by most likely topic and look at one of the document groups
document.most.likely.topic = topics(tm.10, 1)
document.topic.clusters = split(tos.corpus, document.most.likely.topic)
length(document.topic.clusters)   # check to make sure there are 10 clusters corresponding to 10 topics
document.topic.clusters[[3]][[1]]$content
document.topic.clusters[[3]][[2]]$content
document.topic.clusters[[3]][[3]]$content


# cluster documents in topic space
document.topic.probabilities <- tm.10@gamma  # topic distribution for each document
length(document.topic.probabilities)
topic.space.kmeans.clusters = kmeans(document.topic.probabilities, 10)
topic.space.clustered = split(tos.corpus, topic.space.kmeans.clusters$cluster)
topic.space.clustered[[1]][[1]]$content
topic.space.clustered[[1]][[2]]$content
topic.space.clustered[[1]][[3]]$content


###############

# Remove rows in that were removed from the document term matrix
df.noText <- df.noText[-removed.documents, ]  
df.noText$topics <- topics(tm.10, 1) 
class(df.noText$topics)
df.noText$topics <- as.factor(df.noText$topics)
s <- sample(1:nrow(df.noText), 500)
train <- df.noText[s, ]
test <- df.noText[-s, ]

# full model (WITH topics)
model.full <- glm(Response ~ ., data = train, family = "binomial")
summary(model.full)
# at initial glance, this AIC is higher than without the topics

probs <- predict(model.full, test, type = "response")
pred <- rep(0, nrow(test))
pred[probs > .5] <- 1
table(pred, test$Response)
(398 + 6)/(398 + 6 + 70 + 3)
# higher success rate than without the topics
