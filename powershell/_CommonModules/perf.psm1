 <#
.SYNOPSIS
	Retrieves the vital statistics fore one or more machines via perfmon counters.

.PARAMETER ComputerName
	One or more machines to retrieve stats for.  If omitted, stats are returned for the current machine.

.PARAMETER Active
	If set, the statistics will be refreshed every 2 seconds, until you cancel execution.
	
.PARAMETER Hide0
	Hide "0" values from the console output (helpful w/ longer server lists)
#>
function get-perf
{
	param
	(
		[Parameter(ValueFromPipeline=$True)]
		[string[]] $ComputerName,
		[Parameter()]
		[switch] $Active,
		[Parameter()]
		[switch] $Hide0
	)
	begin {
		if(!$ComputerName) {
			$h = hostname;
			$ComputerName = @($h);
		}
		
		$consoleDefault = [console]::ForegroundColor;

		$counterList = @("\PhysicalDisk(*)\Avg. Disk Queue Length"
			,"\physicaldisk(*)\current disk queue length"
			,"\physicaldisk(*)\% disk time"
			,"\processor(_total)\% processor time"
			,"\network interface(*)\bytes total/sec"
			,"\memory\Committed Bytes"
			,"\memory\Available Bytes");
			#,"\memory\% committed bytes in use");

		$maxCVLen = 30;
		$runOnce = !$Active;
	
		$cArr = @();
	}
	process {
		# gather up computer names from input...annoying nuance of how ps handles array input params
		$cArr +=$ComputerName;
	}
	end {

		while($runOnce -or $Active) 
		{ 
			$runOnce = $false;
			
			$cnt = get-counter -computername $cArr -counter $counterList
			
			$allraw = $cnt.CounterSamples | where { $_.Path -notlike "*physicaldisk(_total)*" } | select @{name="machine"; expression={$_.Path.Substring(2,$_.Path.LastIndexOf("\\")-2)}} `
				, CookedValue, Path `
				, @{name="ipath"; expression={ $_.Path.Substring($_.Path.LastIndexOf("\\"))}} | sort machine,ipath `

			$leadLen = ($allraw | select @{name="strLen";expression={ [Math]::Truncate($_.CookedValue).ToString().Length } } | measure-object -property strLen -maximum).maximum
			$trailingLen = ($allraw | select @{name="strLen";expression={ ($_.CookedValue - [Math]::Truncate($_.CookedValue)).ToString().Length -2 } } | measure-object -property strLen -maximum).maximum
			$fmt = $allraw | group-object -property machine;
			
			$maxCVLen = $leadLen + $trailingLen + 1;

			if($Active) { clear; }
			# write each machine to output, colorizing as appropriate
			foreach($svr in $fmt) {
				write-host ("Machine: {0}" -f $svr.Name) -foregroundcolor "Cyan";
				write-host "";
				[double] $availBytes = 0;
				[double] $commitBytes = 0;
				foreach($l in $svr.Group) {
					
					if($l.ipath.IndexOf("\\memory\available bytes") -ne -1) 
					{
						$availBytes = $l.CookedValue;
						continue;
					}
					if($l.ipath.IndexOf("\\memory\committed bytes") -ne -1) 
					{
						$commitBytes = $l.CookedValue;
						continue;
					}
					
					if($Hide0 -eq $true -and $l.CookedValue -eq 0 ) { continue; }
			
					$wColor = $null;
				
					if($wColor -eq $null -and $l.CookedValue -eq 0) { $wColor = "Gray"; }
					if($wColor -eq $null -and $l.ipath.IndexOf("disk queue") -ne -1) { 
						if($l.CookedValue -gt 15) { $wColor = "Yellow"; }
						if($l.CookedValue -gt 30) { $wColor = "Red"; }
					}
					if($wColor -eq $null -and $l.ipath.IndexOf("% processor time") -ne -1) { 
						if($l.CookedValue -gt 75) { $wColor = "Yellow"; } 
						if($l.CookedValue -gt 90) { $wColor = "Red"; } 
						#else { $wColor = "DarkYellow"; } 
					}
					
					if($wColor -eq $null) { $wColor = $consoleDefault; }

					write-host ("{0}{1} {2}" -f [Math]::Truncate($l.CookedValue).ToString().PadLeft($leadLen), ($l.CookedValue - [Math]::Truncate($l.CookedValue)).ToString().PadRight(1).Substring(1).PadRight($trailingLen), $l.ipath) -foregroundcolor $wColor
				}
				
				$totalMem = $availBytes + $commitBytes;
				if($totalMem -gt 0) {
					$wColor = $null;
					$pctMem = $commitBytes / $totalMem * 100.0;
					
					if($pctMem -eq 0 -and $hide0 -eq $true ) {}
					else {
					if($pctMem -gt 75) { $wColor = "Yellow"; } 
					if($pctMem -gt 95) { $wColor = "Red"; } 
					
					if($wColor -eq $null) { $wColor = $consoleDefault; }
					write-host ("{0}{1} {2}" -f [Math]::Truncate($pctMem).ToString().PadLeft($leadLen), ($pctMem - [Math]::Truncate($pctMem)).ToString().PadRight(1).Substring(1).PadRight($trailingLen), "% Memory In Use") -foregroundcolor $wColor
					}
				}
				
				write-host "";
			}
			
			if($Active) { sleep -seconds 2; }
		}
	}
}