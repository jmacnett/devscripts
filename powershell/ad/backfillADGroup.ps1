param 
(
    [Parameter(Mandatory=$true)]
    [string] $srcGroup,
    [Parameter(Mandatory=$true)]
    [string] $tgtGroup
)

"Getting group membership from target..."
$tgtSet = new-object 'system.collections.generic.hashset[string]' @();
get-adgroupmember -identity $tgtGroup | foreach-object { $x = $tgtSet.Add($_.samAccountName); }

# group for those missing
$pendArr = @();

"Getting group membership from source..."
get-adgroupmember -identity $srcGroup | foreach-object {
    if(!$tgtSet.Contains($_.samAccountName)) {
        $pendArr += $_.samAccountName;
    }
}

"Found {0} members to add" -f $pendArr.Count;
if($pendArr.Count -gt 0) {
    "Adding members..."
    add-adgroupmember -identity $tgtGroup -members $pendArr
}
else {
    "No members to add, nothing to do."
}

"Process complete!"