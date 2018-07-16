
SET ANSI_PADDING ON
GO

CREATE NONCLUSTERED INDEX [tblHostPerfStats_Daily_MetricIdTimestampVMHost_Include_UnitValue] ON [dbo].[tblHostPerfStats_Daily]
(
	[MetricId] ASC,
	[Timestamp] ASC,
	[VMHost] ASC
)
INCLUDE ( 	[Unit],
	[Value]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO