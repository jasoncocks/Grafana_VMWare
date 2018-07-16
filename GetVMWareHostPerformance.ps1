
param (
    [Parameter(Mandatory=$true)][string]$VMHostName = ""
)

# Determine script location for PowerShell
$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path

Import-Module $ScriptDir\Out-DataTable.ps1

$dataSource = "[SQLServerInstanceName]"
$database = "[DatabaseName]"
$connectionString = "Server=$dataSource;Database=$database;Integrated Security=True;"

$StartTime = Get-Date
Write-Host "##################################################################################"
Write-Host "# Capture Started at: " $StartTime.ToString("dd MMM yyyy HH:mm:ss")
Write-Host "##################################################################################"

# for the first execution, there will be no stats in the database :-(
# This will act as a default for new stats/servers introduced later
$DefaultStatsSince = (Get-Date).AddHours(-2)

$guestPerfCounter = @(
	"mem.consumed.average",
	"mem.active.average",
	"mem.usage.average",
	"cpu.idle.summation",
	"cpu.ready.summation",
	"cpu.readiness.average",
	"cpu.usage.average",
	"cpu.usagemhz.average",
	"disk.read.average",
	"disk.usage.average",
	"disk.write.average",
	"disk.maxtotallatency.latest",
	"disk.numberreadaveraged.average",
	"disk.numberwriteaveraged.average",
	"net.received.average",
	"net.transmitted.average",
	"net.usage.average",
	"datastore.read.average",
	"datastore.write.average",
	"datastore.numberreadaveraged.average",
	"datastore.numberwriteaveraged.average",
	"datastore.totalreadlatency.average",
	"datastore.totalwritelatency.average",
	"virtualdisk.numberreadaveraged.average",
	"virtualdisk.numberwriteaveraged.average",
	"virtualdisk.read.average",
	"virtualdisk.readloadmetric.latest",
	"virtualdisk.readoio.latest",
	"virtualdisk.totalreadlatency.average",
	"virtualdisk.totalwritelatency.average",
	"virtualdisk.write.average",
	"virtualdisk.writeloadmetric.latest",
	"virtualdisk.writeoio.latest",
	"power.power.average"
)

$hostPerfCounter = @(
	"mem.consumed.average",
	"mem.active.average",
	"mem.usage.average",
	"cpu.usage.average",
	"cpu.usagemhz.average",
	"disk.read.average",
	"disk.usage.average",
	"disk.write.average",
	"disk.maxtotallatency.latest",
	"disk.numberreadaveraged.average",
	"disk.numberwriteaveraged.average",
	"net.received.average",
	"net.transmitted.average",
	"net.usage.average",
	"datastore.read.average",
	"datastore.write.average",
	"datastore.numberreadaveraged.average",
	"datastore.numberwriteaveraged.average",
	"datastore.totalreadlatency.average",
	"datastore.totalwritelatency.average",
	"power.power.average"
)

$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString
$connection.Open()

$command = $connection.CreateCommand()
$command.CommandTimeout = 0
$command.CommandText = "SELECT MAX(Timestamp) as MaxDate FROM tblHostPerfStats_Daily WHERE VMHost = '$VMHostName'"
$hostStatsSince = $DefaultStatsSince

try
{
    $result = $command.ExecuteReader()

    $table = new-object "System.Data.DataTable"
    $table.Load($result)

    $hostStatsSince = ([datetime]$table.MaxDate).ToLocalTime()
}
catch
{
    # swallow error if tblHostPerfStats_Daily table doesn't exist assume default
}

Write-Host "# Host Stats Since: " $hostStatsSince.ToString("dd MMM yyyy HH:mm:ss")

$command.CommandText = "SELECT vCenter_ServerName, vCenter_Username, vCenter_Password FROM tblvCenterCredentials"
$tblvCenterDetails = new-object "System.Data.DataTable"
$tblvCenterDetails.Load($command.ExecuteReader())
$vCenter_ServerName = ([string]$tblvCenterDetails.vCenter_ServerName)
$vCenter_Username = ([string]$tblvCenterDetails.vCenter_Username)
$vCenter_Password = ([string]$tblvCenterDetails.vCenter_Password)

Write-Host "# vCenter Server: " $vCenter_ServerName
Write-Host "# vCenter Username: " $vCenter_Username

$command.CommandText = "SELECT VMGuest, MAX(Timestamp) as MaxTimestamp FROM tblGuestPerfStats_Daily GROUP BY VMGuest"
$tblGuestMaxDate = new-object "System.Data.DataTable"
$tblGuestMaxDate.Load($command.ExecuteReader())

$viServer = Connect-VIServer -Server $vCenter_ServerName -Protocol https -User $vCenter_Username -Password $vCenter_Password -Force

$dtHostPerfStats = Get-VMHost -Name $VMHostName | Get-Stat -Stat $hostPerfCounter -Realtime -Start $hostStatsSince |
    Select MetricId, Unit, 
        @{N="Value";E={ [double]($_.Value -as [double]) }},
        @{N="Timestamp";E={$_.Timestamp.ToUniversalTime() }},
        @{N="VMHost";E={$VMHostName }} |
    Out-DataTable

$bcHost = new-object ("System.Data.SqlClient.SqlBulkCopy") $connection
$bcHost.DestinationTableName = "dbo.tblHostPerfStats_Daily"
$bcHost.WriteToServer($dtHostPerfStats)

### Update Guest as having been polled
$cmdGuestPolled = $connection.CreateCommand()
$cmdGuestPolled.CommandText = "spGuestPolled"
$cmdGuestPolled.CommandType = [System.Data.CommandType]::StoredProcedure

$pGuestName=$cmdGuestPolled.Parameters.Add("@GuestName" , [System.Data.SqlDbType]::NVarChar)

$dtGuestPerfStats = Get-VMHost -Name $VMHostName | Get-VM | where {$_.PowerState -eq "PoweredOn"} | % {
    $vmguest=$_.Name

    # Write-Host "##################################################################################"
    Write-Host "# VM Guest: $vmguest ($VMHostName)"

    $statsSince = ($tblGuestMaxDate | where { $_.VMGuest -eq "$vmguest" }).MaxTimestamp.ToLocalTime()
    if ($statsSince -eq $null)
    {
        # Write-Host "# No previous stats, default date being used."
        $statsSince = $DefaultStatsSince
    }

    Write-Host "# Stats Since: " $statsSince.ToString("dd MMM yyyy HH:mm:ss")
    # Write-Host "##################################################################################"

    $_ | Get-Stat -Stat $guestPerfCounter -Realtime -Start $statsSince |
        Select MetricId, Unit, 
            @{N="Value";E={ [double]($_.Value -as [double]) }},
            @{N="Timestamp";E={$_.Timestamp.ToUniversalTime() }},
            @{N="VMHost";E={$VMHostName }},
            @{N="VMGuest";E={$vmguest }}

    $pGuestName.Value = $vmguest
    $result = $cmdGuestPolled.ExecuteNonQuery() 

} | Out-DataTable

$dtDatabaseUpdate = Get-Date
Write-Host "##################################################################################"
Write-Host "# Writing to database: " $dtDatabaseUpdate.ToString("dd MMM yyyy HH:mm:ss")
Write-Host "# Row Count: " $dtGuestPerfStats.Rows.Count
Write-Host "##################################################################################"

$bcGuest = new-object ("System.Data.SqlClient.SqlBulkCopy") $connection
$bcGuest.BatchSize = 20000
$bcGuest.DestinationTableName = "dbo.tblGuestPerfStats_Daily"
$bcGuest.WriteToServer($dtGuestPerfStats)

### Update Host as having been polled
$cmdHostPolled = $connection.CreateCommand()
$cmdHostPolled.CommandText = "spHostPolled"
$cmdHostPolled.CommandType = [System.Data.CommandType]::StoredProcedure

$pHostName=$cmdHostPolled.Parameters.Add("@HostName" , [System.Data.SqlDbType]::NVarChar)
$pHostName.Value = $VMHostName

$result = $cmdHostPolled.ExecuteNonQuery() 

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
