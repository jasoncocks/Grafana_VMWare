
/****** Object:  StoredProcedure [dbo].[spHostPolled]    Script Date: 16/07/2018 15:56:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[spHostPolled]
@HostName nvarchar(1000)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF EXISTS (
		SELECT 1
		FROM Hosts
		WHERE HostName = @HostName
	)
	BEGIN
		UPDATE
			Hosts
		SET
			LastPolled = GETUTCDATE()
		WHERE
			HostName = @HostName
	END
	ELSE
	BEGIN
		INSERT INTO Hosts (
			HostName,
			LastPolled
		) VALUES (
			@HostName,
           GETUTCDATE()
		)
	END
END
GO
