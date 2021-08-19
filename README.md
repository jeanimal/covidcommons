# covidcommons
Process and analyze data for the Chicagoland covid commons project.

## Example usage

```
library(tidyverse)
library(tidyquant)
library(zoo) # For interpolating na.

source('~/Code/R/covidcommons/preprocess.R')
source('~/Code/R/covidcommons/smoothOutlier.R')

url <- "https://docs.google.com/spreadsheets/d/e/2PACX-1vS8SzaERcKJOD_EzrtCDK1dX1zkoMochlA9iHoHg_RSw3V8bkpfk1mpw4pfL5RdtSOyx_oScsUtyXyk/pub?gid=43720681&single=true&output=csv"

covidByStateRaw <- read_csv(url, col_types = cols(
     .default = col_double(),
     State = col_character()))

covidJoin <- pivotCasesAndDeaths(covidByStateRaw)

# Clean n/a's in the middle of a time series by interpolating..
covidClean <- interpolateNa(covidJoin)

# Clean n/a's at the beginning and end of the data by filling (repeating) up or down.
covidClean <- fillDownThenUpNa(covidClean)

# If a group (State, Race) is all na for cases, then remove.  For Deaths, fill in 0's.
covidClean <- fixGroupsAllNa(covidClean)

# If a group (State, Race) has totals that go down, replace with monotonic regression.
# See https://stat.ethz.ch/R-manual/R-devel/library/stats/html/isoreg.html
# (Non-decreasing totals insure that "new cases" and "new deaths" are never negative.)
covidClean <- replaceWithMonoticRegression(covidClean)

# Make weekly according to the selected day of week.
# (This data set had only Sundays and Wednesdays, and I picked Sunday.)
covidSunday <- selectWeekly(covidClean, "Sunday")

# Add columns for new cases and deaths (better for modeling.)
covidSunday <- calcNewCasesAndDeaths(covidSunday)

write.csv(covidSunday,"output/covid_tracker.csv", row.names = FALSE)

# If you want to smooth spikes with MAD for several windows, use the function below.
# This may take a few minutes to run.
# covidImputed <- covidSunday
# covidImputed <- covidAddMadColumns(covidImputed, "Cases")
# covidImputed <- covidAddMadColumns(covidImputed, "Deaths")
# write.csv(covidImputed,"output/covid_tracker_imputed.csv", row.names = FALSE)

# If you want to add weekly lags... (but without imputed data)

lagRange <- 1:8
col_names <- paste0("NewCases_Lag_", lagRange)

covidSundayLagged <- covidSunday %>%
  group_by(State, Race) %>%
  arrange(Date) %>%
    tq_mutate(
        select     = NewCases,
        mutate_fun = lag.xts,
        k          = lagRange,
        col_rename = col_names
    )
write.csv(covidImputed,"output/covid_tracker_lagged.csv", row.names = FALSE)
```

# How and why

Explanations of these cleaning functions with plots before and after are in this notebook: https://www.kaggle.com/jeanimal/covid-by-race-data-processing
