#load assemblies
[void] [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration")
if($args.Length -eq 0)
{
  Write-Host "The [servername] parameter is required"
  exit
}
$svr = $args[0];
$pool = $null;
if($args.Length -eq 2)
{
	$pool = $args[1];
}
if($pool)
{
	"Retrieving current state of pool {0} on server {1}..." -f $pool,$svr;
	$stateRes = invoke-command $svr { get-webapppoolstate $Using:pool };
	if($stateRes.Value -eq "Stopped") {
		# if the pool is stopped, invoke a "start" insteadl
		"Application pool {0} on server {1} is already stopped!  Invoking start..." -f $pool,$svr;
		invoke-command $svr { start-WebAppPool -Name $Using:pool };
		"Start on server {0} for pool {1} complete" -f $svr,$pool;
	}
	else {
		"Invoking recycle on server {0} for pool {1}..." -f $svr,$pool;
		invoke-command $svr { Restart-WebAppPool -Name $Using:pool };
		"Recycle on server {0} for pool {1} complete" -f $svr,$pool;
	}
}
else
{
	# if no pool name specified, this is a scan.  So scan.
	"No pool specified; retrieving list of pools on server {0}..." -f $svr
	
	[void] [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration")
	$iis = [Microsoft.Web.Administration.ServerManager]::OpenRemote($svr)

	Write-Host "--------------"
	"Application Pools: ({0} total)" -f $iis.ApplicationPools.Count
	Write-Host "--------------"

	[array]$allPools = $iis.ApplicationPools | `
		foreach `
		{ `
			New-Object Object | `
			Add-Member NoteProperty Name $_.Name -PassThru |`
			Add-Member NoteProperty State $_.State -PassThru |`
			Add-Member NoteProperty RuntimeVersion $_.ManagedRuntimeVersion -PassThru |`
			Add-Member NoteProperty PipelineMode $_.ManagedPipelineMode -PassThru |`
			Add-Member NoteProperty Identity $_.ProcessModel.UserName -PassThru | `
			Add-Member NoteProperty Processes $_.WorkerProcesses.Count -PassThru `
		}
		
	$allPools | Format-Table Name, Identity, RuntimeVersion, PipelineMode, Processes, State -AutoSize

	Write-Host "--------------"
}
