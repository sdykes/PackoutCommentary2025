library(tidyverse)

con <- DBI::dbConnect(odbc::odbc(), 
                      dsn = "RockIt", 
                      uid="stuart.dykes@rockitapple.com", 
                      authenticator = "externalbrowser"
)

meanSizeSummaries <- tbl(con, "STG_COMPAC_BATCH") |>
  mutate(Season = case_when(START_TIME >= as.POSIXct('2022-01-01 00:00:00.000') & 
                              START_TIME < as.POSIXct('2023-01-01 00:00:00.000') ~ 2022,
                            START_TIME >= as.POSIXct('2023-01-01 00:00:00.000') & 
                              START_TIME < as.POSIXct('2024-01-01 00:00:00.000') ~ 2023,
                            START_TIME >= as.POSIXct('2024-01-01 00:00:00.000') & 
                              START_TIME < as.POSIXct('2025-01-01 00:00:00.000') ~ 2024,
                            START_TIME >= as.POSIXct('2025-01-01 00:00:00.000') & 
                              START_TIME < as.POSIXct('2026-01-01 00:00:00.000') ~ 2025,
                            TRUE ~ 2021)) |>
  filter(Season == 2024,
         !SIZER_GRADE_NAME %in% c("Low Colour", "Leaf", "Doub", "Doubles", "Capt", "Capture", 
                                  "Class 1.5", "Reject/Spoilt", "Recycle", "Juice", "1.5"),
         SIZE_NAME != "Rejects") |>
  dplyr::select(c(BATCH_ID, GROWER_NAME, GROWER_CODE, MINOR, MAJOR, WEIGHT,VOLUME, 
                  SIZE_NAME, SIZER_GRADE_NAME, START_TIME)) |>
  filter(MINOR > 30,
         MAJOR > 30) |>
  mutate(elong = MAJOR/MINOR,
         SIZE_BAND = case_when(SIZE_NAME %in% c("53/2","53/5","58/5","63/5") ~ "FP",
                               SIZE_NAME %in% c("63/3","63/4","67/4","72/4") ~ "Tube",
                               TRUE ~ "OOS")) |>
  group_by(BATCH_ID, SIZE_BAND) |>
  summarise(NoOfApples = n()) |>
  mutate(PropOfApples = NoOfApples/sum(NoOfApples)) |>
  collect() #|>
  #arrange(Season) 
  #mutate(Season = factor(Season))

DBI::dbDisconnect(con)

SBSummaries <- meanSizeSummaries |>
  pivot_wider(id_cols = BATCH_ID,
              names_from = SIZE_BAND,
              values_from = PropOfApples,
              values_fill = 0)


SBSummaries |>
  ggplot(aes(FP)) +
  geom_histogram()
