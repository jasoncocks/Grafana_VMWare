
/****** Object:  StoredProcedure [dbo].[spStackDailyHostPerfStats]    Script Date: 16/07/2018 15:56:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[spStackDailyHostPerfStats]

AS
BEGIN

	DECLARE @iStackInto int = 2

	BEGIN TRANSACTION

	-- get stack date, and lock table, preventing further bulk inserts
	DECLARE @dtMaxStat DateTime
	SELECT
		   @dtMaxStat = DATEADD(HOUR, DATEDIFF(hour, 0, DATEADD(HOUR, -6, MAX(Timestamp))), 0)
	FROM
		   tblHostPerfStats_Daily
	WITH (TABLOCK, HOLDLOCK)
	 -- this should lock table tblGuestPerfStats_Daily till end of transaction

	SELECT
        VMHost,
        MetricId,
        Unit,
        Timestamp,
        Value
	INTO #residue_stats
	FROM
		tblHostPerfStats_Daily 
	WHERE
		-- dtMaxStat has been floored to the hour, so seconds are 00.
		-- this will work well as performance stats are collected from VMWare as 00 20 & 40s
		-- by taking >= 00s, will ensure all stats for the same period/metric will stack together in the code below
		Timestamp >= @dtMaxStat

	INSERT INTO tblHostPerfStats (
		MetricId,
		Unit,
		Value,
		Timestamp,
		VMHost,
		StackedInto
	)
	SELECT 
		   Stacked.MetricId,
		   Stacked.Unit,
		   Stacked.Value as Value,
		   DATEADD(minute, Stacked.TimePeriod * @iStackInto, '2010-01-01T00:00:00') AS Timestamp,
		   Stacked.VMHost,
		   @iStackInto
	FROM
	(
		   SELECT 
				  FMP.VMHost,
				  FMP.MetricId,
				  FMP.Unit,
				  FMP.TimePeriod,
				  AVG(FMP.Value) as Value
		   FROM 
		   (
				  SELECT
						 AHPS.VMHost,
						 AHPS.MetricId,
						 AHPS.Unit,
						 datediff(minute, '2010-01-01T00:00:00', AHPS.Timestamp)/@iStackInto AS TimePeriod,
						 AHPS.Value
				  FROM tblHostPerfStats_Daily AHPS
						   WHERE Timestamp < @dtMaxStat
		   ) As FMP
		   GROUP BY
				  FMP.VMHost,
				  FMP.MetricId,
				  FMP.Unit,
				  FMP.TimePeriod
	) as Stacked

	TRUNCATE TABLE tblHostPerfStats_Daily

	INSERT INTO tblHostPerfStats_Daily (
		MetricId,
		Unit,
		Value,
		Timestamp,
		VMHost
	)
	SELECT
		MetricId,
		Unit,
		Value,
		Timestamp,
		VMHost
	FROM #residue_stats

	DROP TABLE #residue_stats

	-- release lock
	COMMIT TRANSACTION

END
GO
