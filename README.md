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

covidClean <- fillDownThenUp(covidJoin)
covidWeekly <- selectWeekly(covidClean, "Sunday")
covidImputed <- covidAddMadColumns(covidWeekly, "Cases")

write.csv(covidImputed,"kaggle_imputed.csv", row.names = FALSE)
```

# How and why

Explanations of these cleaning functions with plots before and after are in this notebook: https://www.kaggle.com/jeanimal/covid-by-race-data-processing
