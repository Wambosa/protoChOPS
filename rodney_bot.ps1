

$db = "dac30144dsql01\originations"

$raw = sqlcmd -S $db -d Sandbox_Intern_2015 -Q "[dbo].[pr_retreiveInsult]"

$insult = ([regex]::matches($raw, "\s\w.*\.")).value

$insult