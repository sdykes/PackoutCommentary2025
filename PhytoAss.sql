SELECT 
	AssessmentDefectID,
	qad.AssessmentID,
	Season,
	GraderBatchID,
	GraderBatchMPILotID,
	Defect,
	DefectQty,
	SampleQty,
	MktDefectCode	
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
		GraderBatchMPILotID
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
WHERE MktDefectCode IS NOT NULL
AND TemplateID = 10


