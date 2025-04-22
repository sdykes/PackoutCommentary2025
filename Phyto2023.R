library(tidyverse)

con <- DBI::dbConnect(odbc::odbc(),    
                      Driver = "ODBC Driver 18 for SQL Server", #"SQLServer", #
                      Server = "abcrepldb.database.windows.net",  
                      Database = "ABCPacker2023Repl",   
                      UID = "abcadmin",   
                      PWD = "Trauts2018!",
                      Port = 1433
)

PhytoAss2023 <- DBI::dbGetQuery(con,
                            "SELECT 
	                              AssessmentDefectID,
	                              qad.AssessmentID,
	                              Season,
	                              GraderBatchID,
	                              GraderBatchMPILotID,
	                              Defect,
	                              DefectQty,
	                              SampleQty,
	                              dt.MktDefectCode,
	                              AssessmentDateTime
                            FROM qa_Assessment_DefectT AS qad
                            INNER JOIN
	                              (
	                              SELECT
		                                DefectID,
		                                Defect,
		                                MktDefectCode
	                              FROM qa_DefectT
	                              ) AS dt
                            ON dt.DefectID = qad.DefectID
                            INNER JOIN
	                              (
	                              SELECT
		                                AssessmentID,
		                                GraderBatchID,
		                                TemplateID,
		                                SampleQty,
		                                SeasonID,
		                                GraderBatchMPILotID,
		                                AssessmentDateTime
	                              FROM qa_AssessmentT
	                              ) AS qa
                            ON qa.AssessmentID = qad.AssessmentID
                            INNER JOIN
	                              (
	                              SELECT
		                                SeasonID,
		                                SeasonDesc AS Season
	                              FROM sw_SeasonT
	                              ) AS st
                            ON st.SeasonID = qa.SeasonID
                            INNER JOIN
	                              (
	                              SELECT 
		                                DISTINCT pmr.PIPReqID,
		                                pipr.MktDefectCode,
		                                pipr.DeclarationDesc
	                              FROM pip_Market_RequirementT AS pmr
	                              LEFT JOIN
		                                (
		                                SELECT 
			                                  MktDefectCode,
			                                  prp.PIPReqID,
			                                  PercentLimit,
			                                  ThresholdQty,
			                                  DeclarationDesc
		                                FROM pip_Requirement_PestT AS prp
		                                LEFT JOIN
			                                  pip_RequirementT AS pr
		                                ON pr.PIPReqID = prp.PIPReqID
		                                ) AS pipr
	                              ON pipr.PIPReqID = pmr.PIPReqID
	                              WHERE PIPMarketCode IN ('CHN','TWN')
	                              AND ThresholdQty = 0.0000
	                              ) pip
                            ON pip.MktDefectCode = dt.MktDefectCode
                            WHERE dt.MktDefectCode IS NOT NULL
                            AND TemplateID = 10")

GraderBatchMPILot2023 <- DBI::dbGetQuery(con,
                                     "SELECT 
	                                  GraderBatchMPILotID,
	                                  gb.GraderBatchID,
	                                  MPILotNo,
	                                  FarmCode AS RPIN,
	                                  FarmName AS Orchard,
	                                  PackDate,
	                                  HarvestDate
                                FROM ma_Grader_Batch_MPI_LotT AS gbml
                                INNER JOIN
	                                  ma_Grader_BatchT AS gb
                                ON gb.GraderBatchID = gbml.GraderBatchID
                                INNER JOIN
	                                  sw_FarmT AS ft
                                ON ft.FarmID = gb.FarmID
                                INNER JOIN
	                                  sw_SeasonT AS st
                                ON st.SeasonID = gb.SeasonID")

PIPReq2023 <- DBI::dbGetQuery(con,
                          "SELECT 
	                            GraderBatchMPILotPIPRequirementID,
	                            GraderBatchMPILotID,
	                            gbmlpr.PIPReqID,
	                            DeclarationDesc,
	                            PIPGroup,
	                            MktDefectCode,
	                            PercentLimit,
	                            ThresholdQty
                          FROM ma_Grader_Batch_MPI_Lot_PIP_RequirementT AS gbmlpr
                          INNER JOIN
	                            pip_RequirementT AS prt
                          ON prt.PIPReqID = gbmlpr.PIPReqID
                          INNER JOIN
	                            pip_Requirement_PestT AS prp
                          ON prp.PIPReqID = gbmlpr.PIPReqID")

Cartons2023 <- DBI::dbGetQuery(con,
                           "SELECT 
                                Season, 
	                              GraderBatchMPILotID, 
	                              COUNT(CartonNo) AS Cartons 
	                          FROM ma_CartonT AS ct
                            INNER JOIN
	                              (
	                              SELECT
		                                SeasonID,
		                                SeasonDesc AS Season
	                              FROM sw_SeasonT
	                              ) AS st
                            ON st.SeasonID = ct.SeasonID
                            WHERE CartonExistsFlag = 1
                            GROUP BY Season, GraderBatchMPILotID")

MPILots2023 <- DBI::dbGetQuery(con,
                           "SELECT 
                                GraderBatchMPILotID,
	                              gb.GraderBatchID,
	                              PackDate,
	                              Season
                            FROM ma_Grader_Batch_MPI_LotT AS gbml
                            INNER JOIN
	                              ma_Grader_BatchT AS gb
                            ON gb.GraderBatchID = gbml.GraderBatchID
                            INNER JOIN
	                              (
	                              SELECT
		                                SeasonID,
		                                SeasonDesc AS Season
	                              FROM sw_SeasonT
	                              ) AS st
                            ON st.SeasonID = gb.SeasonID")

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

#========================Generate MinOD==========================================

GBDTeIpu <- GBD |>
  filter(PackSite == "Te Ipu Packhouse (RO)") |>
  mutate(StorageDays = as.integer(PackDate - HarvestDate),
         PackOut = 1-RejectKgs/InputKgs,
         Week = isoweek(PackDate))

minPD <- GBDTeIpu |>
  filter(!is.na(PackOut)) |>
  group_by(Season) |>
  summarise(minHD = min(HarvestDate),
            minPD = min(PackDate)) |>
  mutate(wk = c(as.Date(str_c("2024",{{SundayCloseDate}})),
                as.Date(str_c("2025",{{SundayCloseDate}}))))

#=================================================================================

phytoAssSummary2023 <- PhytoAss  |>
  group_by(GraderBatchMPILotID, Defect, MktDefectCode) |>
  summarise(Season = max(Season, na.rm=T),
            DefectQty = sum(DefectQty, na.rm = T),
            SampleQty = sum(SampleQty, na.rm = T),
            .groups = "drop") |>
  inner_join(GraderBatchMPILot2023, by = "GraderBatchMPILotID")

temp2023 <- phytoAssSummary2023 |>
  left_join(PIPReq2023, by = c("GraderBatchMPILotID", "MktDefectCode")) |>
  filter(!is.na(PIPReqID)) |>
  mutate(storageDays = as.integer(PackDate - HarvestDate))

buggedOutMPILots2023 <- temp2023 |>
  filter(!(MktDefectCode %in% c("LLT", "ROT009"))) |>
  #filter((Season == "2024" & PackDate <= minPD[[1,4]]) | 
  #         (Season == "2025" & PackDate <= minPD[[2,4]])) |>
  ungroup() |>
  group_by(Season, GraderBatchMPILotID) |>
  summarise(batches = n(),
            .groups = "drop") |>
  group_by(Season) |>
  summarise(`With interceptions` = n())

MPILotSummary2023 <- MPILots2023  |>
  #filter((Season == "2024" & PackDate <= minPD[[1,4]]) | 
  #         (Season == "2025" & PackDate <= minPD[[2,4]])) |>
  group_by(Season) |>
  summarise(Total = n()) |>
  arrange(Season) 

boMPILotSummary2023 <- buggedOutMPILots2023 |>
  inner_join(MPILotSummary2023, by = "Season") |>
  mutate(`% bugged out` = `With interceptions`/Total) |>
  mutate(`% bugged out` = scales::percent(`% bugged out`, accuracy = 0.1)) 
