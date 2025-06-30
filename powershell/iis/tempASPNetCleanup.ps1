param
(
	[Parameter(Mandatory=$true)]
    [string] $targetDir,
	[Parameter()]
    [int] $expireAfterDays,
	[Parameter()]
    [int] $expireAfterHours,
	[Parameter()]
    [switch] $inspectRecursive,
    [Parameter()]
    [switch] $dbg
)
$ErrorActionPreference = "Stop" 

$startLoc = (get-location).path;

try
{
	set-location $targetDir
	
	if(!$expireAfterHours) { $expireAfterHours = 0 }
	if($expireAfterDays) {
		$expireAfterHours = $expireAfterHours + ($expireAfterDays * 24);
	}

	# get raw lists
	$rawDirs = ls -directory | where { $_.LastAccessTime -lt [DateTime]::Now.AddHours($expireAfterHours * -1) } | sort-object -property LastAccessTime 
	$rawFiles = ls -file | where { $_.LastAccessTime -lt [DateTime]::Now.AddHours($expireAfterHours * -1) } | sort-object -property LastAccessTime 
	
	# for the directories, inspect the child objects as well for lastaccesstime, and further restrict the deletion list that way
	if($inspectRecursive) {
		$rawDirs = $rawDirs | where { ( get-childitem $_ -recurse | where { $_.LastAccessTime -gt [DateTime]::Now.AddHours($expireAfterHours * -1) }).Count -eq 0 }
	}
	
	"Detected to remove: {0} directories, {1} files" -f $rawDirs.Count, $rawFiles.Count
	
	if($rawDirs.Count -eq 0 -and $rawFiles.Count -eq 0) {
		"Nothing to do, exiting."
		exit
	}
	
	if(!$dbg) {
		try 
		{
			"Stopping iis..."
			stop-service w3svc
			"pausing 10 seconds to allow drainage..."
			sleep 10
			"Deleting files..."
			$rawFiles | remove-item -force -recurse
			"Deleting directories..."
			$rawDirs | remove-item -force -recurse
		}
		finally 
		{
			"Starting iis..."
			start-service w3svc
			"Execution complete!"
		}
    }
    else {
        "Debug flag was set, exiting"
    }
}
finally
{
	set-location $startLoc
}
