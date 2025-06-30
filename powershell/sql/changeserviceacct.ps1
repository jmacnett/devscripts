$svr = $null
$service = $null
$UName=$null
$PWord=$null
for($i=0;$i -lt $args.Length;$i++)
{
	if($args[$i] -eq "-svr")
	{
		$i++;
		$svr = $args[$i];
	} elseif($args[$i] -eq "-svc")
	{
		$i++;
		$service = $args[$i];
	}
	elseif($args[$i] -eq "-u")
	{
		$i++;
		$UName = $args[$i];
	}
	elseif($args[$i] -eq "-pwd")
	{
		$i++;
		$PWord = $args[$i];
	}
}
if(!$svr -or !$service -or !$UName -or !$PWord)
{
	Throw '-svr (servername) -svc (service name) -u (username) -pwd (password) are required!'
	exit
}

#Load the SqlWmiManagement assembly off of the DLL
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement") | out-null
$SMOWmiserver = New-Object ('Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer') $svr #Suck in the server you want

#These just act as some queries about the SQL Services on the machine you specified.
$SMOWmiserver.Services | select name, type, ServiceAccount, DisplayName, Properties, StartMode, StartupParameters | Format-Table
#Same information just pivot the data
$SMOWmiserver.Services | select name, type, ServiceAccount, DisplayName, Properties, StartMode, StartupParameters | Format-List

#Specify the "Name" (from the query above) of the one service whose Service Account you want to change.
$ChangeService=$SMOWmiserver.Services | where {$_.name -eq $service} #Make sure this is what you want changed!

if(!$ChangeService)
{
	Write-Host "Service not found, exiting!"
	exit
}

#Check which service you have loaded first
Write-Host "Before:"
Write-host "---------------------"
$ChangeService
Write-host "---------------------"


# NOTE: these need to be single-quoted values to work!
$ChangeService.SetServiceAccount($UName, $PWord)

#Now take a look at it afterwards
Write-Host "After:"
Write-host "---------------------"
$ChangeService
Write-host "---------------------"

#To soo what else you could do to that service run this:  $ChangeService | gm
