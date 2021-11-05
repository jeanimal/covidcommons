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

See the example preprocessing script.  It generates output in `output/covid_tracker.csv`.

```
source('./basic_preprocess.R')
```

Short summary of what this does:
- takes care of missing values and negative growth.
- output has new cases and new deaths for each week for each state and race.
- parses only Cases_[Race] columns, ignoring Cases_Ethnicity_[HispanicStatus] columns.



# How and why

Explanations of some these cleaning functions with plots before and after are in this notebook: https://www.kaggle.com/jeanimal/covid-by-race-data-processing
