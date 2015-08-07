## Make some notes 
[string] $story = $args[0]
[string] $twigName = $args[1]
[xml] $xmlLog = &svn log -v --xml --limit 150 c:\development\SourceCode\trunk\$twigName

$logentries = $xmlLog.SelectNodes("//logentry")

Write-host "Story Regex" + $story + ":" + $twigName + ":" + ([regex]::matches($story, "(?i)us"))[0].length

if (([regex]::matches($story, "(?i)us"))[0].length -gt 0)
{
	foreach($log in $logentries)
	{
		$build = $log.msg |select-string -pattern "BLD:"

		if ($build)
		{
			$matchingBuilds = $log.msg | select-string -pattern $twigName
			if($matchingBuilds)
			{
				$splitMatches = $matchingBuilds.ToString().Split(":")
				$closestBuildNum = $splitMatches[2]
			} 
		}
		
		$msg = $log.msg | select-string -pattern $args[0] | select-object -First 1
		
		if ($msg)
		{
			$revision = $log.revision
			break
		}
	}	
}
Write-Host "revision: $revision"
if ($revision)
{
	$closestBuildNum
}	
else
{
    "err"
}
