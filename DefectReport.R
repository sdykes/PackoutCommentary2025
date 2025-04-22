library(tidyverse)

con <- DBI::dbConnect(odbc::odbc(),    
                      Driver = "ODBC Driver 18 for SQL Server", 
                      Server = "abcrepldb.database.windows.net",  
                      Database = "ABCPackerRepl",   
                      UID = "abcadmin",   
                      PWD = "Trauts2018!",
                      Port = 1433
)

DefectAssessments <- DBI::dbGetQuery(con,
                           "SELECT 
	                              AssessmentID,
	                              Season,
	                              GraderBatchID,
	                              TemplateName,
	                              BinDeliveryID,
	                              AssessmentDateTime,
	                              SampleQty
                            FROM qa_AssessmentT AS qa
                            INNER JOIN
	                              (
	                              SELECT 
		                                TemplateID,
		                                TemplateName
	                              FROM qa_TemplateT
	                              WHERE TemplateID IN (13,14,28)
	                              ) AS qt
                            ON qt.TemplateID = qa.TemplateID
                            INNER JOIN
	                              (
	                              SELECT
		                                SeasonID,
		                                SeasonDesc AS Season
	                              FROM sw_SeasonT
	                              ) AS st
                            ON st.SeasonID = qa.SeasonID")

Defects <- DBI::dbGetQuery(con,
                           "SELECT 
	                              AssessmentDefectID,
	                              AssessmentID,
	                              Defect,
	                              DefectQty
                            FROM qa_Assessment_DefectT AS qad
                            INNER JOIN
	                              (
	                              SELECT
		                                DefectID,
		                                Defect
	                              FROM qa_DefectT
	                              ) AS dt
                            ON dt.DefectID = qad.DefectID")

DBI::dbDisconnect(con)

SampleQty <- DefectAssessments |>
  group_by(GraderBatchID) |>
  summarise(SampleQty = sum(SampleQty, na.rm=T))

DefectSummary <- Defects |>
  inner_join(DefectAssessments |> select(c(AssessmentID, GraderBatchID)),
             by = "AssessmentID") |>
  group_by(GraderBatchID, Defect) |>
  summarise(DefectQty = sum(DefectQty),
            .groups = "drop") |>
  inner_join(SampleQty, by = "GraderBatchID") |>
  left_join(GBD |> select(c(GraderBatchID, Season, PackDate, InputKgs, RejectKgs)),
            by = "GraderBatchID") |>
  mutate(DefectProp = (DefectQty/SampleQty)*(RejectKgs/InputKgs),
         DefetcPercent = scales::percent(DefectProp, 0.01)) |>
  filter(!is.na(InputKgs))

DefectSummarySub <- DefectSummary |>
  filter((Season == 2024 & (PackDate >= as.Date(minPD[[1,2]]) & PackDate < as.Date(minPD[[1,3]]))) |
           Season == 2025 & (PackDate >= as.Date(minPD[[2,2]]) & PackDate < as.Date(minPD[[2,3]]))) |>
  group_by(Season, Defect) |>
  summarise(DefectQty = sum(DefectQty),
            SampleQty = sum(SampleQty),
            InputKgs = sum(InputKgs),
            RejectKgs = sum(RejectKgs),
            .groups = "drop") |>
  mutate(DefectProp = (DefectQty/SampleQty)*(RejectKgs/InputKgs),
         DefectPercent = scales::percent(DefectProp, 0.01))

# Calculate top 10 defects for 2025 YTD

Top10 <- DefectSummarySub |>
  filter(Season == 2025) |>
  arrange(DefectProp) |>
  slice_tail(n=15) |>
  pull(Defect)

DefectSummarySub |>
  filter(Defect %in% Top10) |>
  mutate(Defect = factor(Defect, levels = Top10)) |>
  ggplot(aes(Defect, DefectProp,colour=Season, fill=Season)) +
  geom_col(position = "dodge") +
  coord_flip() +
  scale_y_continuous("Defect % (as a percentage of total batch)", 
                     labels =  scales::label_percent(1.0)) +
  scale_x_discrete(expand = expansion(mult = 0, add=0)) +
  geom_text(aes(label = DefectPercent, y = DefectProp), size = 2, hjust = -0.2,
            position = position_dodge(width=0.9), colour = "black") +
  scale_fill_manual(values = c("#a9342c","#48762e","#526280","#f6c15f")) +
  scale_colour_manual(values = c("#a9342c","#48762e","#526280","#f6c15f")) +
  ggthemes::theme_economist() + 
  theme(axis.title.x = element_text(margin = margin(t = 7)),
        axis.title.y = element_text(margin = margin(r = 7)),
        axis.text.y = element_text(size = 8, hjust=1),
        axis.text.x = element_text(size = 8),
        plot.background = element_rect(fill = "#F7F1DF", colour = "#F7F1DF"),
        plot.title = element_text(margin = margin(b = 10)),
        legend.text = element_text(size = 8),
        legend.title = element_text(size = 8))

ggsave("firstWeekDefects.png", width = 10, height = 7)  


  
