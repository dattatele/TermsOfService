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
        "https://help.github.com/articles/github-terms-of-service/",
        "https://wikimediafoundation.org/wiki/Terms_of_Use", "http://www.amazon.com/gp/help/customer/display.html/?ie=UTF8&nodeId=508088",
        "https://pages.soundcloud.com/en/legal/terms-of-use.html",
        "https://twitter.com/tos?lang=en",
        "https://cloudant.com/terms/"]

urls2 = ["https://help.instagram.com/478745558852511"]

urls3 = ["https://www.netflix.com/TermsOfUse", "https://www.facebook.com/legal/terms",
         "https://www.youtube.com/t/terms"]

#corresponding companies          
companies = ["Yahoo", "Google", "GitHub", "Wikipedia", "Amazon", "SoundCloud", "Twiter", "Cloudant"]

companies2 = ["Instagram"]

companies3 = ["Netflix", "Facebook", "Youtube"]

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
        paraText = paraText.strip()
        if (paraText != ""):
            capsCount = sum(1 for x in paraText if x.isupper())
            rowValue = pd.Series([companies[index], paraText, len(paraText), 
                                  paraText.count(' '), capsCount])
            df = df.append(rowValue, ignore_index=True)

for url in urls2:
    index = urls2.index(url)
    
    page = urllib.request.urlopen(url)
    soup = BeautifulSoup(page)
    paraTitle = list(soup.find_all('h3'))
    
    for paragraph in paraTitle:
        para = str(paragraph.nextSibling.nextSibling)
        paraText = BeautifulSoup(para).get_text()
        paraText = paraText.strip()
        if (paraText != ""):
            capsCount = sum(1 for x in paraText if x.isupper())
            rowValue = pd.Series([companies2[index], paraText, len(paraText), 
                                  paraText.count(' '), capsCount])
            df = df.append(rowValue, ignore_index=True)
        
for url in urls3:
    index = urls3.index(url)
    
    page = urllib.request.urlopen(url)
    soup = BeautifulSoup(page)
    para = list(soup.find_all('li'))
    
    for paragraph in para:
        paraText = paragraph.get_text()
        paraText = paraText.strip()
        if (paraText != ""):
            capsCount = sum(1 for x in paraText if x.isupper())
            rowValue = pd.Series([companies3[index], paraText, len(paraText), 
                                  paraText.count(' '), capsCount])
            df = df.append(rowValue, ignore_index=True)

#rename columns
df.columns = ["Company", "ParagraphText", "ParagraphLength", "SpacesCount", "CapsCount"]

#calculate count of capital letters to length of paragraph value
df["CapToLegthRatio"] = df["CapsCount"] / df["ParagraphLength"]

#calculate location of each paragraph in the terms of service
#first calculate total paragraphs by company
totalParaByCompany = pd.DataFrame(df.groupby(by=df["Company"]).size())

#get the index of the first occurrence of each company
companies = companies + companies2 + companies3 #put companies all in one vector
firstIndex = []
for company in companies:
    firstIndex.append(list(df["Company"]).index(company))

#mark each paragraph with its order in the terms
df["ParaLocation"] = None
for x in range(0, df.shape[0]):
    if x == 0:
        df["ParaLocation"][x] = 1

    elif df["Company"][x] == df["Company"][x-1]:
        df["ParaLocation"][x] = df["ParaLocation"][x-1] + 1
        
    else:
        df["ParaLocation"][x] = 1

#calculate order/total paragraphs
for x in range(0, df.shape[0]):
    company = df["Company"][x]
    companyTotalPara = int(str(totalParaByCompany.loc[company]).split()[1]) #grabs total paragraphs from groupby results
    df["ParaLocation"][x] = df["ParaLocation"][x] / companyTotalPara

#print to csv
df.to_csv("TermsOfService.csv", index=False)
