SELECT 
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
GROUP BY Season, GraderBatchMPILotID