

con <- DBI::dbConnect(odbc::odbc(),    
                      Driver = "ODBC Driver 18 for SQL Server", 
                      Server = "abcrepldb.database.windows.net",  
                      Database = "ABCPackerRepl",   
                      UID = "abcadmin",   
                      PWD = "Trauts2018!",
                      Port = 1433
)

BinsHarvestedJosh <- DBI::dbGetQuery(con,
                                 "SELECT 
	                                    Season,
	                                    BinDeliveryID,
	                                    HarvestDate,
	                                    NoOfBins,
	                                    PresizeFlag,
	                                    StorageSite,
	                                    PickNo
                                  FROM ma_Bin_DeliveryT AS bd
                                  INNER JOIN
                                      sw_Pick_NoT AS pn
                                  ON pn.PickNoID = bd.PickNoID
                                  INNER JOIN
	                                    (
	                                    SELECT
		                                      CompanyID,
		                                      CompanyName AS StorageSite
	                                    FROM sw_CompanyT
  	                                  ) AS ct
                                  ON ct.CompanyID = bd.FirstStorageSiteCompanyID
                                  INNER JOIN
	                                    (
	                                    SELECT
		                                  SeasonID,
		                                  SeasonDesc AS Season
	                                    FROM sw_SeasonT
	                                    ) AS st
                                  ON st.SeasonID = bd.SeasonID")

DBI::dbDisconnect(con)


MaxMinHD <- BinsHarvestedJosh |>
  filter(!PresizeFlag) |>
  group_by(Season) |>
  summarise(minHD = min(HarvestDate),
            maxHD = max(HarvestDate)) |>
  mutate(HarvestDays = as.numeric(maxHD-minHD))

MeanHarvestRate <- BinsHarvestedJosh |>
  filter((Season == 2024 & HarvestDate <= MaxMinHD$maxHD[[1]]) |
           (Season == 2025 & HarvestDate <= MaxMinHD$maxHD[[2]]),
         !PresizeFlag) |>
  group_by(Season) |>
  summarise(NoOfBins = sum(NoOfBins)) |>
  left_join(MaxMinHD |> select(c(Season, HarvestDays)),
            by = "Season") |>
  mutate(BinsPerDay = NoOfBins/HarvestDays)

PickNo <- BinsHarvestedJosh |>
  group_by(Season, PickNo) |>
  summarise(NoOfBins = sum(NoOfBins)) |>
  mutate(NoOfBins/sum(NoOfBins))








  
  
