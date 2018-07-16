
# Determine script location for PowerShell
$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path

Import-Module $ScriptDir\Out-DataTable.ps1

$dataSource = "SVRREDSQVLV002"
$database = "VMWareStats"
$connectionString = "Server=$dataSource;Database=$database;Integrated Security=True;"

$StartTime = Get-Date
Write-Host "##################################################################################"
Write-Host "# Capture Started at: " $StartTime.ToString("dd MMM yyyy HH:mm:ss")
Write-Host "##################################################################################"

# for the first execution, there will be no stats in the database :-(
# This will act as a default for new stats introduced later
$DefaultStatsSince = (Get-Date).ToUniversalTime().AddHours(-2)

$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString
$connection.Open()

#$command = $connection.CreateCommand()
#$command.CommandText = "SELECT VMGuest, MAX(Timestamp) as MaxTimestamp FROM tblGuestPerfStats GROUP BY VMGuest"
#$tblFGuestMaxDate = new-object "System.Data.DataTable"
#$tblFGuestMaxDate.Load($command.ExecuteReader())

$viServer = Connect-VIServer -Server SVRREDVCENTRE1 -Protocol https -User administrator@imprimus.local -Password HP1nvent! -Force

$cluster = Get-Cluster

<#

# Not sure what to do with snapshots at the moment
$DtGuestSnapShots =
    Get-VM | Get-Snapshot |
        Select @{Name="GuestName";Expression={$_.VM.Name}},
            Name,
            Description,
            SizeGB,
            Created,
            @{Name="PointInTime";Expression={$PointInTime}} |
    Out-DataTable
#>

$dtDataStore =
    Get-Datastore | Select @{Name="DataStoreName";Expression={$_.Name}},
        @{Name="ClusterName";Expression={$cluster.Name}},
        @{Name="FreeSpaceGB";Expression={$_.FreeSpaceGB}},
        @{Name="CapacityGB";Expression={$_.CapacityGB}},
        @{Name="TimeStamp";Expression={(Get-Date).ToUniversalTime()}} |
    Out-DataTable

$dtDatabaseUpdate = Get-Date
Write-Host "##################################################################################"
Write-Host "# Writing to database: " $dtDatabaseUpdate.ToString("dd MMM yyyy HH:mm:ss")
Write-Host "# Data Store: " $dtDataStore.Rows.Count
# Write-Host "# Snashots  : " $DtGuestSnapShots.Rows.Count
Write-Host "##################################################################################"

<#
$bcSnapshot = new-object ("System.Data.SqlClient.SqlBulkCopy") $connection
$bcSnapshot.DestinationTableName = "dbo.tblSnapshots_NOTYEETCREATED"
$bcSnapshot.WriteToServer($DtGuestSnapShots)
#>

$bcDataStore = new-object ("System.Data.SqlClient.SqlBulkCopy") $connection
$bcDataStore.DestinationTableName = "dbo.tblDataStores"
$bcDataStore.WriteToServer($dtDataStore)

$connection.Close()

Disconnect-VIServer -Server $viServer -Confirm:$false

$EndTime = Get-Date
Write-Host "##################################################################################"
Write-Host "# Capture Finished at: " $EndTime.ToString("dd MMM yyyy HH:mm:ss")
Write-Host "##################################################################################"

$ts = New-TimeSpan -Start $StartTime -End $EndTime
Write-Host "##################################################################################"
Write-Host "# Total Duration: " $ts.ToString();
Write-Host "##################################################################################"
