library(tidyquant)

doIt <- function(covidWeekly, colName) {
    if (colName == "TmpTmp") {
      stop("Cannot process column named TmpTmp")
    }
    if (!colName %in% colnames(covidWeekly)) {
      stop(paste0("Column '", colName, "' not found"))
    }
    # Temporarily rename to column to TmpTmp for easier dplyr processing.
    colnames(covidWeekly)[which(colnames(covidWeekly)==colName)] <- "TmpTmp"
    covidWeekly
}

# This adds new columns with MAD values
# CasesMad_9: MAD with a 9-day window
# CasesMad_7: MAD with a 7-day window
# CasesMad_5: MAD with a 5-day window
# CasesMad_3: MAD with a 3-day window
# CasesMad: The mad for the widest window that has a value.
# It is inefficient and may take a few minutes to run.
covidAddMadColumns <- function(covidWeekly, colName) {
  if (colName == "TmpTmp") {
    stop("Cannot process column named TmpTmp")
  }
  if (!colName %in% colnames(covidWeekly)) {
    stop(paste0("Column '", colName, "' not found"))
  }
  # Temporarily rename to column to TmpTmp for easier dplyr processing.
  colnames(covidWeekly)[which(colnames(covidWeekly)==colName)] <- "TmpTmp"
  covidWeekly %>%
  group_by(State, Race) %>%
  arrange(Date) %>%
  tq_mutate(
    # tq_mutate args
    select     = TmpTmp,
    mutate_fun = rollapply,
    # rollapply args
    width      = 9,
    # partial    = TRUE,
    align      = "center",
    FUN        = mad,
    # mad args
    # tq_mutate args
    col_rename = "TmpTmp_9"
  ) %>%
  tq_mutate(
    # tq_mutate args
    select     = TmpTmp,
    mutate_fun = rollapply,
    # rollapply args
    width      = 7,
    # partial    = TRUE,
    align      = "center",
    FUN        = mad,
    # mad args
    # tq_mutate args
    col_rename = "TmpTmp_7"
  ) %>%
  tq_mutate(
    # tq_mutate args
    select     = TmpTmp,
    mutate_fun = rollapply,
    # rollapply args
    width      = 5,
    # partial    = TRUE,
    align      = "center",
    FUN        = mad,
    # mad args
    # tq_mutate args
    col_rename = "TmpTmp_5"
  ) %>%
  tq_mutate(
    # tq_mutate args
    select     = TmpTmp,
    mutate_fun = rollapply,
    # rollapply args
    width      = 3,
    # partial    = TRUE,
    align      = "center",
    FUN        = mad,
    # mad args
    # tq_mutate args
    col_rename = "TmpTmp_3"
  ) %>% 
  mutate(
    CasesMad = coalesce(TmpTmp_9, TmpTmp_7, TmpTmp_5, TmpTmp_3, TmpTmp), 
  )
  # Restore the column name.
  colnames(covidWeekly)[which(colnames(covidWeekly)=="TmpTmp")] <- colName
  colnames(covidWeekly)[which(colnames(covidWeekly)=="TmpTmp_9")] <- paste0(colName, "_9")
  colnames(covidWeekly)[which(colnames(covidWeekly)=="TmpTmp_7")] <- paste0(colName, "_7")
  colnames(covidWeekly)[which(colnames(covidWeekly)=="TmpTmp_5")] <- paste0(colName, "_5")
  colnames(covidWeekly)[which(colnames(covidWeekly)=="TmpTmp_3")] <- paste0(colName, "_3")
  covidWeekly
}