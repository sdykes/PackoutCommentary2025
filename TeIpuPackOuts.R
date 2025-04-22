library(tidyverse)

con <- DBI::dbConnect(odbc::odbc(),    
                      Driver = "ODBC Driver 18 for SQL Server", 
                      Server = "abcrepldb.database.windows.net",  
                      Database = "ABCPackerRepl",   
                      UID = "abcadmin",   
                      PWD = "Trauts2018!",
                      Port = 1433
)

GBD <- DBI::dbGetQuery(con,
                       "SELECT 
	                          gbt.GraderBatchID,
	                          ss.Season,
	                          gbt.PackDate,
	                          gbt.HarvestDate,
	                          ft.FarmCode,
	                          ft.FarmName,
	                          st.ProductionSite,
	                          ct.PackSite,
	                          mt.MaturityCode,
	                          stt.StorageType,
	                          pkt.PickNo,
	                          gbt.InputKgs,
	                          gbt.WasteOtherKgs + ISNULL(rjk.JuiceKgs,0) + ISNULL(rsk.SampleKgs,0) AS RejectKgs
                        FROM ma_Grader_BatchT AS gbt
                        LEFT JOIN
	                          (
	                          SELECT
		                            PresizeOutputFromGraderBatchID AS GraderBatchID,
		                            SUM(TotalWeight) AS JuiceKgs
	                          FROM ma_Bin_DeliveryT
	                          WHERE PresizeProductID = 278
	                          GROUP BY PresizeOutputFromGraderBatchID
	                          ) AS rjk
                        ON gbt.GraderBatchID = rjk.GraderBatchID
                        LEFT JOIN
	                          (
	                          SELECT 
		                            pd.GraderBatchID,
		                            SUM(pd.NoOfUnits*pt.NetFruitWeight) AS SampleKgs
	                          FROM ma_Pallet_DetailT AS pd
	                          INNER JOIN
		                            (
		                            SELECT
			                              ProductID,
			                              NetFruitWeight
		                            FROM sw_ProductT
		                            WHERE SampleFlag = 1
		                            ) AS pt
	                          ON pd.ProductID = pt.ProductID
	                          GROUP BY GraderBatchID
	                          ) AS rsk
                        ON gbt.GraderBatchID = rsk.GraderBatchID
                        INNER JOIN
	                          (
	                          SELECT 
		                            SeasonID,
		                            SeasonDesc AS Season
	                          FROM sw_SeasonT
	                          ) AS ss
                        ON gbt.SeasonID = ss.SeasonID
                        INNER JOIN 
	                          (
	                          SELECT
		                            FarmID,
		                            FarmCode,
		                            FarmName
	                          FROM sw_FarmT
	                          ) AS ft
                        ON gbt.FarmID = ft.FarmID
                        INNER JOIN
	                          (
	                          SELECT	
		                            SubdivisionID,
		                            SubdivisionCode AS ProductionSite
	                          FROM sw_SubdivisionT
	                          ) AS st
                        ON gbt.SubdivisionID = st.SubdivisionID
                        INNER JOIN
	                          (
	                          SELECT
		                            CompanyID,
		                            CompanyName AS PackSite
	                          FROM sw_CompanyT
	                          ) AS ct
                        ON gbt.PackingCompanyID = ct.CompanyID
                        INNER JOIN
	                          (
	                          SELECT
		                            MaturityID,
		                            MaturityCode
	                          FROM sw_MaturityT
	                          ) AS mt
                        ON gbt.MaturityID = mt.MaturityID
                        INNER JOIN
	                          (
	                          SELECT
		                            StorageTypeID,
		                            StorageTypeDesc AS StorageType
	                          FROM sw_Storage_TypeT
	                          ) AS stt
                        ON gbt.StorageTypeID = stt.StorageTypeID
                        INNER JOIN
	                          (
	                          SELECT
		                            PickNoID,
		                            PickNoDesc AS PickNo
	                          FROM sw_Pick_NoT
	                          ) AS pkt
                        ON gbt.PickNoID = pkt.PickNoID
                        WHERE PresizeInputFlag = 0"
                       )

DBI::dbDisconnect(con)

GBDTeIpu <- GBD |>
  filter(PackSite == "Te Ipu Packhouse (RO)") |>
  mutate(StorageDays = as.integer(PackDate - HarvestDate),
         PackOut = 1-RejectKgs/InputKgs,
         Week = isoweek(PackDate))


GBDTeIpu |>
  filter(Season == 2025,
         !is.na(PackOut)) |>
  ggplot(aes(x=PackDate, y=PackOut)) +
  geom_point()

# Total interim packout

GBDTeIpu |>
  filter(Season == 2025,
         !is.na(PackOut)) |>
  summarise(InputKgs = sum(InputKgs),
            RejectKgs = sum(RejectKgs)) |>
  mutate(PackOut = 1-RejectKgs/InputKgs)


# First Week packing comparison 2024 vs 2025

# Establish dates for first week of packing

minPD <- GBDTeIpu |>
  filter(!is.na(PackOut)) |>
  group_by(Season) |>
  summarise(minHD = min(HarvestDate),
            minPD = min(PackDate)) |>
  mutate(wk1 = minPD+7)

# calculate first week packouts

GBDTeIpu |>
  filter(!is.na(PackOut),
         (Season == 2024 & (PackDate >= as.Date(minPD[[1,3]]) & PackDate < as.Date(minPD[[1,4]]))) |
         Season == 2025 & (PackDate >= as.Date(minPD[[2,3]]) & PackDate < as.Date(minPD[[2,4]]))) |>
  group_by(Season) |>
  summarise(InputKgs = sum(InputKgs),
            RejectKgs = sum(RejectKgs)) |>
  mutate(PackOut = round(1-RejectKgs/InputKgs,3),
         PackOut = scales::percent(PackOut, 0.1)) |>
  select(-c(InputKgs, RejectKgs)) |>
  kableExtra::kbl(col.names = c("Season", "Packout"),
                  escape=T,
                  booktabs = T, 
                  align=c("l", "r"),
                  linesep = "") |>
  kableExtra::kable_styling(full_width=F) |>
  kableExtra::row_spec(c(0), bold=T)










