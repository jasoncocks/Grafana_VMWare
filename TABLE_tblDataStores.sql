
/****** Object:  Table [dbo].[tblDataStores]    Script Date: 16/07/2018 15:56:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblDataStores](
	[DataStoreName] [nvarchar](1000) NULL,
	[ClusterName] [nvarchar](1000) NULL,
	[FreeSpaceGB] [decimal](20, 5) NULL,
	[CapacityGB] [decimal](20, 5) NULL,
	[Timestamp] [datetime] NULL
) ON [PRIMARY]
GO
