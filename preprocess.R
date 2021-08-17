library(tidyverse)

# Turn the many columns for Cases and Deaths into rows.
pivotCasesAndDeaths <- function(covidByStateRaw) {
  keyCols <- c("Date", "State")
  valCols <- c("Cases_White", "Cases_Black", "Cases_Latinx", "Cases_Asian", "Cases_AIAN", "Cases_NHPI", "Cases_Multiracial", "Cases_Other", "Cases_Unknown")
  cases <- pivot_longer(covidByStateRaw[c(keyCols, valCols)], all_of(valCols), names_to="Race", names_pattern = "Cases_(.*)", values_to="Cases")

  keyCols <- c("Date", "State") # Same as before.
  valCols <- c("Deaths_White", "Deaths_Black", "Deaths_Latinx", "Deaths_Asian", "Deaths_AIAN", "Deaths_NHPI", "Deaths_Multiracial", "Deaths_Other", "Deaths_Unknown")
  deaths <- pivot_longer(covidByStateRaw[c(keyCols, valCols)], all_of(valCols), names_to="Race", names_pattern = "Deaths_(.*)", values_to="Deaths")

  full_join(cases, deaths)
}

fillDownThenUp <- function(pivotedCovid) {
  covidClean <- pivotedCovid
  # Apply the fill function "down" to replace an NA with a value from the previous date, if it had a value.
  covidClean <- covidClean %>% group_by(State, Race) %>% arrange(Date, .by_group = TRUE) %>% fill(Cases, Deaths, .direction = "down")
  # Now the only NA are at the start, since they had no previous row.  They could be zero,
  # but I think it's more likely the same value as the most recent data,  So now fill "up".
  covidClean <- covidClean %>% group_by(State, Race) %>% arrange(Date, .by_group = TRUE) %>% fill(Cases, Deaths, .direction = "up")
  covidClean
}

# The output of this funciton is a dataframe with no na's.
# It achieves this in two ways.
#
# If a group (State, Race) has all cases na, the group will be filtered out.  Fewer rows.
# If a group (State, Race) has all deaths na, the Deaths will be converted to 0's.
fixGroupsAllNa <- function(pivotedCovid) {
  pivotedCovid <- pivotedCovid %>% 
    group_by(State, Race)  %>% 
    filter(!all(is.na(Cases)))
  pivotedCovid <- pivotedCovid %>%
    mutate(Deaths = ifelse(is.na(Deaths), 0, Deaths))
}

# Use monotonic regression to prevent total number of Cases/Deaths from going down.
# Monotonic regression will error on missing values so they must be cleaned first.
replaceWithMonoticRegression <- function(pivotedCovid) {
  pivotedCovid <- pivotedCovid %>%
    group_by(State, Race) %>%
    mutate(Cases = isoreg(Date, Cases)$yf) %>%
    mutate(Deaths = isoreg(Date, Deaths)$yf) %>%
    distinct(Date, .keep_all=TRUE)
}

selectWeekly <- function(pivotedCovid, dayOfWeek) {
  covidDay <- pivotedCovid
  covidDay[["DateAsDate"]] <- as.Date(as.character(covidDay[["Date"]]), "%Y%m%d")
  covidDay[["Weekday"]] <- weekdays(covidDay[["DateAsDate"]])
  covidWeekly <- covidClean[covidDay$Weekday==dayOfWeek,]
  covidWeekly[["DateAsDate"]] <- as.Date(as.character(covidWeekly[["Date"]]), "%Y%m%d")
  covidWeekly
}
