<#
	.SYNOPSIS
		Retrieves pre-formatted disk usage information for all drives on a machine.

	.PARAMETER ComputerName
		(Optional) Name of a remote computer.  If not provided, the value is that of the local machine.
#>
function Get-DriveSpace
{
	param
	(
		[Parameter()]
		[string[]] $ComputerName
	)
	
	if(!$ComputerName) {
		$h = hostname;
		$ComputerName = @($h);
	}
	
	get-WmiObject win32_logicaldisk -Computername $ComputerName | select PSComputerName `
		, DeviceID `
		, DriveType `
		, @{ name="Size_gb"; expression={ $_.Size/1024/1024/1024 }} `
		, @{ name="Used_gb"; expression={ ($_.Size-$_.FreeSpace)/1024/1024/1024 }} `
		, @{ name="FreeSpace_gb"; expression={ $_.FreeSpace/1024/1024/1024 }} `
		, @{ name="PercentAvailable"; expression={($_.FreeSpace/$_.Size * 100.0)} } `
		#| format-table -auto `
}