library(tidyverse)

Season <- list(2022:2025)
mean <- list(meanSizeSummaries$meanMass)
sd <- list(meanSizeSummaries$sdMass)

generateMassData <- function(Season, mean, sd) {
  MassData <- tibble(
    Data = rnorm(1000, mean, sd))
  return(MassData)
}

meanSizeSummaries_sub <- meanSizeSummaries |>
  select(c(Season,meanMass,sdMass))

generateMassData(2022, meanSizeSummaries$meanMass[[1]], meanSizeSummaries$sdMass[[1]])

temp <- meanSizeSummaries |>
  pmap(~generateMassData(..1, ..2, ..3)) |>
  bind_cols()

colnames(temp) <- c(2022:2025)

write_csv(temp, "MassDistributions.csv")


