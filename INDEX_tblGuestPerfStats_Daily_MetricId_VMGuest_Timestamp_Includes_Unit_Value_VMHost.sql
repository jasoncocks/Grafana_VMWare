
SET ANSI_PADDING ON
GO

CREATE NONCLUSTERED INDEX [tblGuestPerfStats_Daily_MetricId_VMGuest_Timestamp_Includes_Unit_Value_VMHost] ON [dbo].[tblGuestPerfStats_Daily]
(
	[MetricId] ASC,
	[VMGuest] ASC,
	[Timestamp] ASC
)
INCLUDE ( 	[Unit],
	[Value],
	[VMHost]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO