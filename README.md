# covidcommons
Process and analyze data for the Chicagoland covid commons project.

## Example usage

```
library(tidyverse)
library(tidyquant)

url <- "https://docs.google.com/spreadsheets/d/e/2PACX-1vS8SzaERcKJOD_EzrtCDK1dX1zkoMochlA9iHoHg_RSw3V8bkpfk1mpw4pfL5RdtSOyx_oScsUtyXyk/pub?gid=43720681&single=true&output=csv"

covidByStateRaw <- read_csv(url, col_types = cols(
     .default = col_double(),
     State = col_character()))

source('~/Code/R/covidcommons/preprocess.R')
source('~/Code/R/covidcommons/smoothOutlier.R')

covidJoin <- pivotCasesAndDeaths(covidByStateRaw)

# Clean n/a's at the beginning and end of the data by filling.
covidClean <- fillDownThenUp(covidJoin)

# If a group (State, Race) is all na, then either remove or fill in 0's.
covidClean <- fixGroupsAllNa(covidClean)
# If a group (State, Race) has totals that go down, replace with monotonic regression.
# See https://stat.ethz.ch/R-manual/R-devel/library/stats/html/isoreg.html
# (Non-decreasing totals insure that "new cases" and "new deaths" are never negative.)
covidClean <- replaceWithMonoticRegression(covidClean)

# Make weekly according to the selected day of week.
# (This data set had only Sundays and Wednesdays, and I picked Sunday.)
covidWeekly <- selectWeekly(covidClean, "Sunday")

# Smooth spikes with MAD for several windows.
# This may take a few minutes.
covidImputed <- covidAddMadColumns(covidWeekly, "Cases")

write.csv(covidImputed,"output/covid_imputed.csv", row.names = FALSE)
```

# How and why

Explanations of these cleaning functions with plots before and after are in this notebook: https://www.kaggle.com/jeanimal/covid-by-race-data-processing
