
# coding: utf-8

# In[1]:

import pandas as pd
import scipy
import numpy as np
import re # only for use of regex flags in pandas str methods


# In[2]:

df = pd.read_csv("TermsOfService_Agreement.csv")


# In[3]:

# 0-1 flags for presence of special keywords
df['Arbitration'] = (df.ParagraphText.str.contains('arbitration', flags=re.IGNORECASE)).astype('int8')
df['ThirdParty'] = (df.ParagraphText.str.contains('third[- ]party', flags=re.IGNORECASE)).astype('int8')
df['Waiver'] = (df.ParagraphText.str.contains('waiver', flags=re.IGNORECASE)).astype('int8')

# Some more paragraph stats
df['ParagraphWords'] = (df.ParagraphText.str.count(' ')) + 1 # a space was the best indicator of actual words I could find 
                                                             # without inserting a great deal of complication.
df['ParagraphSentences'] = (df.ParagraphText.str.count(r'\.[ $]')) # period followed by space or end-of-string
df['Quotes'] = df.ParagraphText.str.count(r'["]')
df['Parentheses'] = df.ParagraphText.str.count(r'[)(]') - 2*df.ParagraphText.str.count(r'\([a-zA-Z0-9]\)')
df['AvgWordLength'] = (df.ParagraphLength - (df.ParagraphWords - 1) - df.ParagraphSentences - df.Quotes - 
                       df.Parentheses)/df.ParagraphWords
#  (total chars - #spaces - #periods - #quotechars - #parentheses)/#words
# not exact, but a good approximation.


# In[4]:

print(df.columns)
print(np.sort(df.Company.unique()))


# In[5]:

annotations = sorted(list(df.columns[df.columns.str.contains('Import')]))
companies = np.sort(df.Company.unique())
print(annotations)
print(companies)


# In[10]:

# Define the assignments
assignments = {annotations[0]:tuple(companies[[2,3,4,8,10,12]]),
               annotations[1]:tuple(companies[[0,1,3,5,7,8]]),
               annotations[2]:tuple(companies[[0,5,6,10,11,12]]),
               annotations[3]:tuple(companies[[1,2,4,6,7,11]])}
print(assignments)


# In[11]:

# Inspect null values
nulls = {}
for name in list(assignments.keys()):
    a = df[name][df.Company.isin(assignments[name])]
    a = a[a.isnull()]
    nulls[name] = a.index
    
for name in list(nulls.keys()):
    indices = nulls[name]
    print(name + ":")
    print(df.loc[indices, ['Company'] + list(nulls.keys())])


# In[12]:

# Reassign nulls to values in neighboring annotation columns
for name in list(nulls.keys()):
    indices = nulls[name]
    df.loc[indices, name] = np.all(df.loc[indices, list(nulls.keys())].values, axis = 1).astype('int8')
    #print(np.all(df.loc[indices, list(nulls.keys())].values, axis = 1).astype('int8'))
    print(df.loc[indices, ['Company'] + list(nulls.keys())])


# In[98]:

# Initialize agreement metric matrices
nrows = len(assignments)*(len(assignments) - 1)/2

index = pd.MultiIndex(levels=[list(assignments.keys()), list(assignments.keys())], names = ['rater1','rater2'], labels = [[0,0,0,1,1,2],[1,2,3,2,3,3]])
metrics = pd.DataFrame({"sampleSize":np.NaN, "VI":np.NaN, "cohen":np.NaN, "companies":np.array("",dtype='S32')}, index = index)
print(metrics)


# In[99]:

# Compute the agreement metrics and put in a dataframe
max_variation = np.log(4)
for i in range(0,(len(assignments)-1)):
        for j in range((i+1),len(assignments)):
                name1 = list(assignments.keys())[i]
                name2 = list(assignments.keys())[j]
                
                matrix = pd.crosstab(df[name1],df[name2])
                total = matrix.values.sum()
                proportions = matrix.values/total
                
                margin1 = np.add.reduce(proportions, axis=0)
                margin2 = np.add.reduce(proportions, axis=1)
                independent = np.zeros(shape = [len(margin1), len(margin2)], dtype = 'float')
                for k in range(0, len(margin2)):
                    independent[k,:] = margin1*margin2[k]
                print(name1 + " " + name2 + ":")
                print("Actual:")
                print(proportions.round(3))
                print("Independent:")
                print(independent.round(3))
                
                random = independent.diagonal()
                actual = proportions.diagonal()
                kappa = (np.sum(actual) - np.sum(random))/(1 - np.sum(random))
                
                entropy1 = -1*np.sum(margin1*np.log(margin1))
                entropy2 = -1*np.sum(margin2*np.log(margin2))
                mutualInformation = np.sum(proportions*np.log(proportions/independent))
                variation = (entropy1 + entropy2 - 2*mutualInformation)/max_variation
                
                metrics.loc[(name1,name2),['cohen','VI','sampleSize','companies']] = [kappa,variation,total,
                                                                                      str(set(assignments[name1]).intersection(set(assignments[name2])))]
                
print(metrics)


# In[167]:

# Create the final response column(s)
df['responseAND'] = np.array(np.int(), dtype = 'int8')
df['responseOR'] = np.array(np.int(), dtype = 'int8')
for i in range(0,df.shape[0]):
    # The intersection of the positive labels (AND)
    df.loc[i,"responseAND"] = np.min(df.ix[i][list(assignments.keys())].dropna().values)
    # The union of the positive labels (OR)
    df.loc[i,"responseOR"] = np.max(df.ix[i][list(assignments.keys())].dropna().values)


# In[168]:

# Write data to csv
df.to_csv("TermsOfService.csv", index=False)
metrics.reset_index().to_csv("AgreementMetrics.csv", index=False)

