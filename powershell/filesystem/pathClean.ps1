$ErrorActionPreference = "Stop"

function processDir {
	param([string] $cur, [bool] $preserve)

	[int] $nval = 0;
	
	$dirs = Get-ChildItem $cur -Attributes Directory
	for($i = 0; $i -lt $dirs.Count;$i++)
	{
		$newPath = [System.IO.Path]::Combine($dirs[$i].Parent.FullName, $nval)
		$nval++;
		while([System.IO.Directory]::Exists($newPath))
		{
			$newPath = [System.IO.Path]::Combine($dirs[$i].Parent.FullName, $nval)
			$nval++;
		}
		Write-Host ("newPath: '{0}' to '{1}'" -f $dirs[$i].FullName, $newPath);
		# $dirs[$i].MoveTo($newPath)
		move-Item -path $dirs[$i].FullName -destination $newPath -Force
	}

	# get renamed directories
	Get-ChildItem $cur -Attributes Directory | Foreach-Object { processDir $_.FullName $false }
	
	# kill it
	if(!$preserve)
	{
		Write-Host ('deleting directory "{0}"...' -f $cur)
		Remove-Item -path $cur -Recurse -Force
	}
}

$root = $null
$preserveRoot = $true
for($i=0;$i -lt $args.Length; $i++)
{
	if($args[$i] -eq "-path") {
		$i++;
		$root = $args[$i];
	} elseif ([System.IO.Directory]::Exists($args[$i]) -and !$root) {
		$root = $args[$i];
	} elseif ($args[$i] -eq "-rmRoot") {
		$preserveRoot = $false
	}
}
if(!$root)
{
	Write-Error ('Invalid parameters! Usage: 
> .\pathClean.ps1 [-path] Path [-rmRoot]
		-path <root directory path, required> value: "{0}"
		-rmRoot <if present, remove specified path value as well>' -f $root)
	exit
}
if(![System.IO.Directory]::Exists($root))
{
	Write-Error ('Provided path "{0}" does not exist!  Execution aborted.' -f $root)
	exit
}
Write-Host ('Recursively scanning path "{0}" for items to remove...' -f $root)

processDir $root $preserveRoot

Write-Host "Execution complete!"
