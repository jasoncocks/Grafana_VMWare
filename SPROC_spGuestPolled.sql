
/****** Object:  StoredProcedure [dbo].[spGuestPolled]    Script Date: 16/07/2018 15:56:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[spGuestPolled]
@GuestName nvarchar(1000)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF EXISTS (
		SELECT 1
		FROM Guests
		WHERE GuestName = @GuestName
	)
	BEGIN
		UPDATE
			Guests
		SET
			LastPolled = GETUTCDATE()
		WHERE
			GuestName = @GuestName
	END
	ELSE
	BEGIN
		INSERT INTO Guests (
			GuestName,
			LastPolled
		) VALUES (
			@GuestName,
           GETUTCDATE()
		)
	END
END
GO
