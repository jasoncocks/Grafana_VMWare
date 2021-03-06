
/****** Object:  StoredProcedure [dbo].[spStackDailyGuestPerfStats]    Script Date: 16/07/2018 15:56:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[spStackDailyGuestPerfStats]

AS
BEGIN

	DECLARE @iStackInto int = 2

	BEGIN TRANSACTION

	-- get stack date, and lock table, preventing further bulk inserts
	DECLARE @dtMaxStat DateTime
	SELECT
		   @dtMaxStat = DATEADD(HOUR, DATEDIFF(hour, 0, DATEADD(HOUR, -6, MAX(Timestamp))), 0)
	FROM
		   tblGuestPerfStats_Daily
	WITH (TABLOCK, HOLDLOCK)
	 -- this should lock table tblGuestPerfStats_Daily till end of transaction

	SELECT
        VMGuest,
        VMHost,
        MetricId,
        Unit,
        Timestamp,
        Value
	INTO #residue_stats
	FROM
		tblGuestPerfStats_Daily 
	WHERE
		-- dtMaxStat has been floored to the hour, so seconds are 00.
		-- this will work well as performance stats are collected from VMWare as 00 20 & 40s
		-- by taking >= 00s, will ensure all stats for the same period/metric will stack together in the code below
		Timestamp >= @dtMaxStat

	INSERT INTO tblGuestPerfStats (
		MetricId,
		Unit,
		Value,
		Timestamp,
		VMHost,
		VMGuest,
		StackedInto
	)
	SELECT 
		   Stacked.MetricId,
		   Stacked.Unit,
		   Stacked.Value as Value,
		   DATEADD(minute, Stacked.TwentyMinutesPeriod * @iStackInto, '2010-01-01T00:00:00') AS Timestamp,
		   Stacked.VMHost,
		   Stacked.VMGuest,
		   @iStackInto
	FROM
	(
		   SELECT 
				  FMP.VMGuest,
				  FMP.VMHost,
				  FMP.MetricId,
				  FMP.Unit,
				  FMP.TwentyMinutesPeriod,
				  AVG(FMP.Value) as Value
		   FROM 
		   (
				  SELECT
						 AGPS.VMGuest,
						 AGPS.VMHost,
						 AGPS.MetricId,
						 AGPS.Unit,
						 datediff(minute, '2010-01-01T00:00:00', AGPS.Timestamp)/@iStackInto AS TwentyMinutesPeriod,
						 AGPS.Value
				  FROM tblGuestPerfStats_Daily AGPS
						   WHERE Timestamp < @dtMaxStat
		   ) As FMP
		   GROUP BY
				  FMP.VMGuest,
				  FMP.VMHost,
				  FMP.MetricId,
				  FMP.Unit,
				  FMP.TwentyMinutesPeriod
	) as Stacked

	TRUNCATE TABLE tblGuestPerfStats_Daily

	INSERT INTO tblGuestPerfStats_Daily (
		MetricId,
		Unit,
		Value,
		Timestamp,
		VMHost,
		VMGuest
	)
	SELECT
		MetricId,
		Unit,
		Value,
		Timestamp,
		VMHost,
		VMGuest
	FROM #residue_stats

	DROP TABLE #residue_stats

	-- release lock
	COMMIT TRANSACTION

END
GO
