
/****** Object:  StoredProcedure [dbo].[spStackGuestPerfStats]    Script Date: 16/07/2018 15:56:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[spStackGuestPerfStats]
@iStackDays int,
@iStackInto int,
@iStackFrom int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @iTmpStackedInto int = @iStackFrom * -1

	-- whole days only !!!
	DECLARE @dtMaxStat DateTime = DATEADD(DAY,datediff(DAY,0,GETUTCDATE() - @iStackDays),0)

	-- identify metric/records that need stacking, by flagging them as negative StackedInto values
	-- these will be deleted
	UPDATE tblGuestPerfStats
	SET
		StackedInto = @iTmpStackedInto
	WHERE
		Timestamp < @dtMaxStat AND
		StackedInto = @iStackFrom

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
		DATEADD(minute, Stacked.StackedPeriod * @iStackInto, '2010-01-01T00:00:00') AS Timestamp,
		Stacked.VMHost,
		Stacked.VMGuest,
		@iStackInto
	FROM
	(
		SELECT 
			GPS.VMGuest,
			GPS.VMHost,
			GPS.MetricId,
			GPS.Unit,
			GPS.StackedPeriod,
			AVG(GPS.Value) as Value
		FROM 
		(
			SELECT
				VMGuest,
				VMHost,
				MetricId,
				Unit,
				datediff(minute, '2010-01-01T00:00:00', Timestamp)/@iStackInto AS StackedPeriod,
				Value
			FROM tblGuestPerfStats
			WHERE
				StackedInto = @iTmpStackedInto
		) As GPS
		GROUP BY
			GPS.VMGuest,
			GPS.VMHost,
			GPS.MetricId,
			GPS.Unit,
			GPS.StackedPeriod
	) as Stacked

	-- delete records flagged with negative stack value
	DELETE
	FROM tblGuestPerfStats
	WHERE
		StackedInto = @iTmpStackedInto
	
END
GO
