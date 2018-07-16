
/****** Object:  Table [dbo].[tblGuestPerfStats_Daily]    Script Date: 16/07/2018 15:56:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblGuestPerfStats_Daily](
	[MetricId] [nvarchar](100) NOT NULL,
	[Unit] [nvarchar](50) NULL,
	[Value] [float] NOT NULL,
	[Timestamp] [datetime] NOT NULL,
	[VMHost] [nvarchar](100) NOT NULL,
	[VMGuest] [nvarchar](100) NOT NULL
) ON [PRIMARY]
GO
