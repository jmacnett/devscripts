param
(
	[Parameter()]
	[string] $rootPath,
	[Parameter()]
	[int] $displayDepth,
	[Parameter()]
	[switch] $showFiles
)

clear
$sw = new-object 'System.Diagnostics.Stopwatch' @();
$sw.Start();

# get defaults if unspecified
if(!$rootPath) {
	$rootPath = (get-location).Path
}

$masterNode = @{
	path=$rootPath
	totalSize=0.0
	totalCnt=0
	depth=0
	cnodes = @()
};

function writeLine{
	param([string] $toWrite)
	
	"[{0}] {1}" -f $sw.Elapsed, $toWrite;
}

function processDir {
	param
	(
		$curPath,
		$parentNode
	)
	
	# get file objects
	$depth = $parentNode.depth + 1;
	
	clear;
	"=>$curPath"
	
	$prefix = '';
	for($i=0;$i -lt $depth * 2;$i++) {
		$prefix += ' ';
	}
	
	$fList = get-childitem $curPath -force -file
	foreach($f in $fList) {
		$parentNode.cnodes += @{
			path=("{0}{1}" -f $prefix, $f.Name)
			totalSize=$f.Length
			depth=$depth
			cnodes=$null
		};
		$parentNode.totalSize += $f.Length;
		$parentNode.totalCnt++;
	}
	
	$fList = $null;
	
	# get directory objects 
	$dList = get-childitem $curPath -force -directory
	foreach($d in $dList) { 
		$parentNode.totalCnt++;
		$dNode = @{
			path=("{0}{1}" -f $prefix, $d.Name)
			totalSize=0.0
			totalCnt=0
			depth=$depth
			cnodes = @()
		};
		processDir $d.FullName $dNode
		$parentNode.totalSize += $dNode.totalSize;
		$parentNode.totalCnt += $dNode.totalCnt;
		$parentNode.cnodes += $dNode;
	}
}

writeLine "Beginning processing...";

processDir $rootPath $masterNode

$sw.Stop();

writeLine "Processing complete!  Results:";
"";

function parseAsFile {
	param($node)
	if($node.isFile) { 
		return ""; 
	} 
	
	return "{0} items, " -f $node.totalCnt;
}

function printResult {
	param
	(
		$node,
		$curDepth
	)
	
	#$node.depth;
	if($displayDepth -and ($node.depth -gt $displayDepth)) { return; }

	# print this item
	$prefix = '';
	# for($i=0;$i -lt $curDepth;$i++) {
		# $prefix += ' ';
	# }

	if($node.cnodes -ne $null -or ($node.cnodes -eq $null -and $showFiles) )
	{
		"{0}{1} ({2}{3} mb)=>" -f $prefix `
			,$node.path`
			,(parseAsFile $node) `
			,($node.totalSize / 1024.0 / 1024.0); 
	}	
	
	# print sorted child items
	$newDepth = $curDepth + 2;
	foreach($ci in ($node.cnodes | sort-object totalSize -desc)) {
		printResult $ci $newDepth;
	}
}

printResult $masterNode 0

# $resArr.Count
# $resArr | format-table -auto name, cnt, sizeMB

"";
"Total elapsed: {0} ss" -f ($sw.ElapsedMilliseconds / 1000.0)
"";
# "{0} ({1} items, {2} mb)=>" -f $masterNode.path, $masterNode.totalCnt, ($masterNode.totalSize / 1024.0 / 1024.0);

# foreach($cn in $masterNode.cnodes) {
	# "  {0} ({1} items, {2} mb)=>" -f $cn.path, $cn.totalCnt, ($cn.totalSize  / 1024.0 / 1024.0);
# }