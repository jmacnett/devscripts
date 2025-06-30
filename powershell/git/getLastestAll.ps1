param
(
	[Parameter()]
	[string[]] $rootPaths
)
$runPath = (get-location).Path;
if(!$rootPaths -or $rootPaths.count -eq 0) { 
	$rootPaths = @((get-location).Path);
}

foreach($path in $rootPaths) {
	
	set-location $path
	get-childitem -hidden -recurse ".git" | select @{name="parentName";expression={ $_.Parent.FullName } } `
		| foreach-object  { cd $_.parentName; "Processing {0}..." -f $_.parentName; git fetch --prune; git pull; }
	set-location $path
}
set-location $runPath