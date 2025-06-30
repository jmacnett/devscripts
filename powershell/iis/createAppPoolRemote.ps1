<#
.SYNOPSIS
	Creates an IIS application pool on the specified server.

.PARAMETER AppPoolName
	The ApplicationPool name to create
.PARAMETER ComputerName
	The computer to create the application pool on.
.PARAMETER ServiceAccountName
	(optional) Service Account name to run app pool under
.PARAMETER ServiceAccountPassword
	(optional) Service Account password to run app pool under
#>
param
(
	[Parameter(Mandatory=$true)]
	[string] $AppPoolName, 
	[Parameter(Mandatory=$true)]
	[string] $ComputerName, 
	[Parameter()]
	[string] $ServiceAccountName, 
	[Parameter()]
	[string] $ServiceAccountPassword
)

invoke-command -computername $computername -script { 
	$pool = New-WebAppPool $using:AppPoolName
	if($using:ServiceAccountName -and $using:ServiceAccountName.length -gt 0) {
		$pm = $pool.processModel;
		#$pm | get-member
		$pm.userName = $using:ServiceAccountName
		$pm.password = $using:ServiceAccountPassword
		$pm.identityType = 3
		$pool | set-item
	}
	$pool.Start()
}
