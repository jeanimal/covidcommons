# This is a basic pre-process that takes care of missing values and negative growth.
# The output has new cases and new deaths for each week for each state and race.
# This parses only Cases_[Race] columns, ignoring Cases_Ethnicity_[HispanicStatus] columns.
# It will save data to the file at output/covid_tracker.csv.

library(tidyverse)
library(zoo)

source('./lib/preprocess.R')

outputFile = "output/covid_tracker.csv"

# Download data
url <- "https://docs.google.com/spreadsheets/d/e/2PACX-1vS8SzaERcKJOD_EzrtCDK1dX1zkoMochlA9iHoHg_RSw3V8bkpfk1mpw4pfL5RdtSOyx_oScsUtyXyk/pub?gid=43720681&single=true&output=csv"

covidByStateRaw <- read_csv(url, col_types = cols(
  .default = col_double(),
  State = col_character()))

# Pivot cases and deaths.
covidJoin <- pivotCasesAndDeaths(covidByStateRaw)

# Clean n/a's in the middle of a time series by interpolating.
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

write.csv(covidSundayClean, outputFile, row.names = FALSE)


