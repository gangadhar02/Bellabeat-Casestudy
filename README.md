# Bellabeat-Casestudy

# Introduction

This is a case study for Bellabeat: a high-tech company that manufactures health-focused smart products, specifically designed for women. Their goal is to help their users be aware and understand their current habits to make healthier decisions.

### Scenario

I’m a junior data analyst working on the marketing analyst team at Bellabeat. Urška Sršen, cofounder and Chief Creative Officer of Bellabeat, believes that analyzing smart device fitness data could help unlock new growth opportunities for the company. I have been asked to focus on one of Bellabeat’s products and analyze smart device data to gain insight into how consumers are using their smart devices. The insights I discover will then help guide marketing strategy for the company.I will present your analysis to the Bellabeat executive team along with my recommendations for Bellabeat’s marketing strategy.

# 1. Ask Phase

### **Business Task**

The aim of this analysis is to analyze smart devices fitness data and determine how it could help unlock new growth opportunities for Bellabeat. We will focus on one of Bellabeat’s products: Bellabeat app. The Bellabeat app provides users with health data related to their activity, sleep, stress, menstrual cycle, and mindfulness habits. This data can help users better understand their current habits and make healthy decisions. The Bellabeat app connects to their line of smart wellness products. We will try to answer questions like:

- What are some trends in smart device usage?
- How could these trends apply to Bellabeat customers?
- How could these trends help influence Bellabeat marketing strategy?

### ****Stakeholders****

1. **Urška Sršen**: Bellabeat’s cofounder and Chief Creative Officer
2. **Sando Mur**: Mathematician and Bellabeat’s cofounder; key member of the Bellabeat executive team
3. **Bellabeat marketing analytics team**: A team of data analysts responsible for collecting, analyzing, and reporting data that helps guide Bellabeat’s marketing strategy.

# 2. Prepare Phase

### About Dataset

**FitBit Fitness Tracker Data** (CC0: Public Domain, dataset made available through Mobius): This Kaggle data set contains personal fitness tracker from thirty fitbit users. Thirty eligible Fitbit users consented to the submission of personal tracker data, including minute-level output for physical activity, heart rate, and sleep monitoring. It includes information about daily activity, steps, and heart rate that can be used to explore users’ habits.

### Metadata

1. Title: FitBit Fitness Tracker Data
2. Source: Kaggle
3. Uploader: Mobius
4. Type: CSV
5. Last Updated: 05.12.2016
6. License: CC0: Public Domain
7. Tables: 18


### Data Limitations and biases:

1. The dataset contains 33 fitbit users and we dont have any gender specified data, due to this we could encounter sampling bias.
2. The data is 5 years old so, the results may not be relavent for present scenario.
3. Data is also limited by Demographic, Time, Duration, Sample size
- That is why we will give our case study an operational approach

# 3. Process Phase

### Data i’m using from dataset for analysis :

- Steps data of 33 users for 31 days.
- Sleep activity data of 33 users for 31 days.
- Calories burnt by 33 users for 31 days.
- So we use these tables from data set - dailyActivity_merged , hourlyIntensities_merged, sleepDay_merged, hourlySteps_merged, hourlyCalories_merged.

### Steps in cleaning & processing data

**Considering the huge dataset i have used R to process & clean the data , also R helps us in data visualisation.**

1. Loading libraries into R.
2. Importing data to R.
3. Looking into data for understanding data set.
4. Spotting and removing Duplicates, N/A values.
5. Making variable names and date time consistent.
6. Transforming data - Merging & Keeping only the data we require. 

Code used for processing data —> [Processing](https://github.com/gangadhar02/Bellabeat-Casestudy/blob/main/1.Process-Phase.R)
