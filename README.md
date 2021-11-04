# covidcommons
Process and analyze data for the Chicagoland covid commons project.

The data comes from covid tracker, which stopped updating in March 2021.  The main dependent variables are:
- Cases (total number of cases of covid by that date)
- Deaths (total number of deaths attributed to covid by that date)

Note that states have different ways of tracking everything:
- race / ethnicity (whether they use latinx)
- what counts as "covid" (based on symptoms only or requiring a test)
- what counts as a "covid death" (in community, in hospital, 30 days after release, etc.)

## Example usage

```
library(tidyverse)
library(tidyquant) # For imputing outliers with MAD hampel filter.
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

# The first row of every state / race has NA for NewCases and NewDeaths because
# they are a difference from a previous row and these have no previous row.  Remove those.
covidSundayClean <- covidSunday[complete.cases(covidSunday), ]

write.csv(covidSundayClean,"output/covid_tracker.csv", row.names = FALSE)

#### Optional additional processing ###

# If you want to smooth spikes with MAD for several windows, use the function below.
# This may take a few minutes to run.
# covidImputed <- covidSundayClean
# covidImputed <- covidAddMadColumns(covidImputed, "Cases")
# covidImputed <- covidAddMadColumns(covidImputed, "Deaths")
# write.csv(covidImputed,"output/covid_tracker_imputed.csv", row.names = FALSE)

# If you want to add weekly lags... (but without imputed data)
# These are used for modelers to link deaths to recently-detected covid cases.

lagRange <- 1:8
col_names <- paste0("NewCases_Lag_", lagRange)

covidLagged <- covidSundayClean %>%
  group_by(State, Race) %>%
  arrange(Date) %>%
    tq_mutate(
        select     = NewCases,
        mutate_fun = lag.xts,
        k          = lagRange,
        col_rename = col_names
    )
write.csv(covidLagged,"output/covid_tracker_lagged.csv", row.names = FALSE)
```

# How and why

Explanations of these cleaning functions with plots before and after are in this notebook: https://www.kaggle.com/jeanimal/covid-by-race-data-processing
