# Remove Redundant Paragraphs & Wikipedia ToS
# Final Datacleaning Step

AG <- read.csv('Data/TermsOfService_Agreement.csv', stringsAsFactors = F)
colnames(AG)

# Row Index to be Deleted from Data Frame
toDelete <- c(608,614,615,618,622,629,639,643,649,654,661,681,687,699,710,720,726,730,732,735,740,744,748,758)
View(AG$ParagraphText[toDelete])
AG <- AG[-toDelete,] 

# Delete Wikipedia
AG <- AG[-which(AG$Company == "Wikipedia"),]

# Write data to csv
write.csv(AG,"Data/TermsOfService_Agreement_Final.csv")

