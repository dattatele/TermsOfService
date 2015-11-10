# -*- coding: utf-8 -*-
"""
Created on Tue Nov 10 10:33:02 2015

@author: k_schinkel
"""

import pandas as pd
from bs4 import BeautifulSoup
import urllib

#locations of terms of service
urls = ["http://policies.yahoo.com/us/en/yahoo/terms/utos/index.htm", "https://www.google.com/intl/en/policies/terms/",
        "https://www.facebook.com/legal/terms", "https://help.instagram.com/478745558852511",
        "https://www.netflix.com/TermsOfUse", "https://help.github.com/articles/github-terms-of-service/",
        "https://wikimediafoundation.org/wiki/Terms_of_Use", "http://www.amazon.com/gp/help/customer/display.html/?ie=UTF8&nodeId=508088",
        "https://www.youtube.com/t/terms"]

#corresponding companies          
companies = ["Yahoo", "Google", "Facebook", "Instagram", "Netflix", "GitHub", "Wikipedia", "Amazon", "Youtube"]

#create empty data frame
df = pd.DataFrame()

#for each url, open the site, extract soup, find all paragraphs
#then, for each paragraph, get text and add the text and company name to the dataframe
for url in urls:
    index = urls.index(url)
    
    page = urllib.request.urlopen(url)
    soup = BeautifulSoup(page)
    para = list(soup.find_all('p'))
    
    for paragraph in para:
        paraText = paragraph.get_text()
        rowValue = pd.Series([companies[index], paraText])
        df = df.append(rowValue, ignore_index=True)

#rename columns
df.columns = ["Company", "ParagraphText"]

#print to csv
#DF.to_csv("TermsOfService.csv", index=False)