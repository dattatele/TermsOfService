# Is this Paragraph Important?
#### Classifying ‘Terms of Service’ Components through Text Mining
![alt text](https://www.eff.org/files/clickwrap_trans.png)

## Methodology
1. Scrape Terms of Service (ToS) Agreements from Yahoo, Google, GitHub, Amazon, SoundCloud, Twitter, Cloudant, Instagram, Netflix, Facebook, Youtube, iCloud
2. Break up each ToS into paragraphs - treat each paragraph as "document" for text mining
3. Manual annotations by all four group members - calculate Cohen's Kappa
4. Perform basic feature engineering: length of paragraph, count of spaces, count of capitalized letters, location of paragraph, word count, count of quotation marks, sentence count, count of parentheses, average word count
5. Perform LDA topic modeling in R with k=50 and stemming and add topics to features
6. Logistic Modeling

## Results
Measuring by recall and F-score, our methodology was most effective when Cohen’s kappa was highest between the two raters.

To improve our model, we recommend employing two legal experts to manually label our terms of service agreements. We then recommend calculation of Cohen’s kappa and iteratively completing the labelling process until a satisfactory agreement measurement is reached. We also recommend employing a third legal expert to decide a category for particular paragraphs where the two experts disagree. We believe this approach would mitigate variability.
