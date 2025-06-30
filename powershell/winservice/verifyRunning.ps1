# collect configuration 
$computer = $null
$svcName = if($args.length -gt 0) { $args[0] } else { $null }
$clist = $null
$args.length
for($i=0;$i -lt $args.length;$i++) {
	if ($args[$i] -eq "-svc") {
		$i++;
		$svcName = $args[$i];
	} elseif ($args[$i] -eq "-clist") {
		$i++;
		$clist = $args[$i].split(',');
	}
}
$svcName
if(!$svcName) {
	throw ('Invalid parameters! Usage: 
> .\verifyRunning.ps1 [-svc] servicename [-clist "<comma-delimited list of computer names>"]')
	exit
}
if(!$clist) {
	if($computer) {
		$clist = @($computer);
	} else {
		$clist = @((Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain)
	}
}

# build final string
$flist = [System.String]::Join(",", $clist);
Write-Host "Gathering information about the following computers:";
$clist | Format-List

# do remote invocations
$svcList = $null
$job = invoke-command -ComputerName $clist -ScriptBlock { Get-Service $Using:svcName | foreach-object -process { if($_.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Running) { $_.Start() } } } -AsJob
Wait-Job $job
$svcList = Receive-Job $job # will be null on this call
# gather results
$job = invoke-command -ComputerName $clist -ScriptBlock { Get-Service $Using:svcName } -AsJob
Wait-Job $job
$svcList = Receive-Job $job
if(!$svcList)
{
	Write-Host "Returned service list variable is null!  Execution aborted!"
	return
}

# display results
foreach($svc in $svcList) {
	$svc
	# if($svc.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Running) {
		# Write-Host ("Starting service on {0}..." -f $svc.MachineName)
		# $svc.Start();
		# Write-Host ("Service start attempt complete for {0}" -f $svc.MachineName)
	# }
}

Write-Host "Scan complete!";