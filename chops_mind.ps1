#chops server + pmo death

$mail_server = 'emailrelay.corpint.net'
$sql_db= 'SQLdevREPORTING.nonprod.corpint.net\REPORTING01'

#region rallybot metohds
function RallyStatusReport {
	
	$to_address		= 'bdowdy@santanderconsumerusa.com'
	$from_address 	= 'sdiaz@santanderconsumerusa.com'
	
	$shhh = ./RallyBot.exe -iteration-report $args
	
	$message = Get-Content 'email_body.txt' | out-string
	
	Send-MailMessage -To $to_address -Subject "Status Report" -BodyAsHtml -Body $message -from $from_address -SmtpServer $mail_server
	
	"`nStatus report sent to $to_address`n"
}

function GetLatestBuildNumber {
	#https://msdn.microsoft.com/en-us/library/microsoft.powershell.commands.htmlwebresponseobject_properties(v=vs.85).aspx
	
	if($args.length -gt 0){
		
		$twig_name = (Get-Culture).TextInfo.ToTitleCase($args)
		
		#case sensitive links.
		if($twig_name -eq "Autodirect"){
			$twig_name = "AutoDirect"
		}
		if($twig_name -eq "Autoindirect"){
			$twig_name = "AutoIndirect"
		}		
		
	}else{
		
		$twig_name = "AutoIndirect"
	}
	
	$link = "http://rchpwvadtmgm01.prod.corpint.net/ccnet/server/local/project/$twig_name%20Build/ViewProjectReport.aspx"
	$raw = ((Invoke-Webrequest -Uri $link).parsedHtml.getElementById("projectStatus")).innerText
	([regex]::matches($raw, "\d{1,5}") | %{$_.value})
}

function GetAllImportantBuilds {
	
	#$logs = &svn log --limit 175 c:\development\SourceCode\trunk
   
    ## Overwrite these if we find anything
    $latest_shared = "trunk/SharedComponents - " + (GetLatestBuildNumber "Shared%20Components")
    $latest_indirect = "trunk/AutoIndirect - " + (GetLatestBuildNumber "AutoIndirect")
    $latest_direct = "trunk/AutoDirect - " + (GetLatestBuildNumber "AutoDirect")
    $latest_tools = "trunk/Tools - " + (GetLatestBuildNumber "Tools")
       
    # if ($logs){
    #     ## Now we want any commits that match the string "Build-*"
    #     $latest_shared = $logs | select-string -pattern "Build-Shared" | select-object -First 1
    #     $latest_indirect = $logs | select-string -pattern "Build-AutoIndirect" | select-object -First 1
    #     $latest_direct = $logs | select-string -pattern "Build-AutoDirect" | select-object -First 1
    #     $latest_tools = $logs | select-string -pattern "Build-Tools" | select-object -First 1  
    # }	

	echo "$latest_shared`n$latest_direct`n$latest_indirect`n$latest_tools`n"
}


## Push stuff around
function PushToTest {
[CmdletBinding()]
Param ([parameter(mandatory=$false)][String]$packageName)
	$to_address		= 'bdowdy@santanderconsumerusa.com'
	$cc_address		= 'sdiaz@santanderconsumerusa.com'
	$from_address 	= 'sdiaz@santanderconsumerusa.com'
	$package_name 	= if($packageName){ $packageName}else{"RIMS"}
	$build_num		= GetLatestBuildNumber
	$greeting		= "morning"
	$greeting		= if(([int](get-date -Format 'HH') -gt 11)){"afternoon"}else{$greeting}
	$greeting		= if(([int](get-date -Format 'HH') -gt 17)){"evening"}else{$greeting}
	
	$message		= "Good $greeting,`n`nPlease deploy to TST1.`n`nName: $package_name`nBranch: AutoIndirect`nBuild: $build_num`n`nIf there is any information i left out that yall need. Please let me know.`n-shon"
	
	Send-MailMessage -To $to_address -Cc $cc_address -Subject "Push Request RIMS" -Body $message -from $from_address -SmtpServer $mail_server
	
	"`nPush request created...`n"
	$message
}

function LoopProcess {
		
	Do {
		
		&.\ParcelPirate.exe
		
		$parcels = (ls slack)
		#todo: move this parcel processing to another function block. so that the variables are descoped
		if($parcels.Length -gt 0) {
			
			foreach($file in $parcels) {
				
				
				$json = ""
				$message = ""
					
				$json = $file | cat -raw | ConvertFrom-Json
				
				foreach($message in $json){
							
					$response = ""
											
					if($message.user.length -gt 0) {
						#ignore messages sent by the bot (self)
							
						if(([regex]::matches($message.text, "(?i)chuck"))[0].length -gt 0) {
							
							$response = .\GetRandomChuckNorrisJoke.exe
						}elseif(([regex]::matches($message.text, "(?i)joke"))[0].length -gt 0){
							
							$response = .\GetRandomChuckNorrisJoke.exe
						}elseif(([regex]::matches($message.text, "(?i)report"))[0].length -gt 0){
							
							$needed_arg = ([regex]::matches($message.text, "\d\d"))[0]
													
							if($needed_arg.length -gt 0) {
								
								$response = RallyStatusReport $needed_arg
							}else{
								
								$response = " I need an iteration number to do that..."
								$response += .\rodney_bot.ps1
							}
							
						}elseif(([regex]::matches($message.text, "(?i)push"))[0].length -gt 0){
							
							if(([regex]::matches($message.text, "(?i)test"))[0].length -gt 0){
								
								$response = PushToTest
							}
							
						}elseif(([regex]::matches($message.text, "(?i)build|(?i)latest|(?i)most recent"))[0].length -gt 0){
							
							$singleRequest = ([regex]::matches($message.text, "(?i)late|(?i)recent"))[0]
							
							if($singleRequest.length -gt 0){
								
								$twig = ([regex]::matches($message.text, "(?i)autoindirect|(?i)autodirect|(?i)tools"))[0]
								
								$response = "The latest build for $twig is "
								$response += GetLatestBuildNumber $twig
								
							}elseif(([regex]::matches($message.text, "(?i)all"))[0].length -gt 0){
								
								$response = GetAllImportantBuilds
							}
							
						}elseif(([regex]::matches($message.text, "(?i)help"))[0].length -gt 0){
							
							if(([regex]::matches($message.text, "(?i)need|(?i)want"))[0].length -gt 0){
								
								$response = "Call the helpdesk you noob..."
								$response += .\rodney_bot.ps1
							}
							
						}elseif(([regex]::matches($message.text, "(?i)lol"))[0].length -gt 0){
							
							$response = "what do you find so funny? I wish i could laugh out loud..."
																
						}elseif(([regex]::matches($message.text, "(?i)fool"))[0].length -gt 0){
							
							$response = "i hope you are not refering to me as a fool..."
							$response += .\rodney_bot.ps1
																
						}elseif(([regex]::matches($message.text, "(?i)damn|(?i)dammit|(?i)fuck|(?i)bitch|(?i)bastard"))[0].length -gt 0){
							
							$response = "simmer down emotional human..."
							$response += .\rodney_bot.ps1
																
						}elseif(([regex]::matches($message.text, "(?i)best"))[0].length -gt 0){
							
							if(([regex]::matches($message.text, "(?i)chops|(?i)your|(?i)youre|(?i)you're"))[0].length -gt 0){
							
								$response = "mirror mirror on the wall, who is the most bestest bot of them all? return self;"								
							}
						}elseif(([regex]::matches($message.text, "(?i)hello|(?i)\bhi\b"))[0].length -gt 0){
							
							if(([regex]::matches($message.text, "(?i)chops"))[0].length -gt 0){
							
								$response = "greetings fragile human..."								
							}
						}elseif(([regex]::matches($message.text, "(?i)powershell"))[0].length -gt 0){
							
							$response = "did you say 'powershell'?! My heart and soul..."
																
						}elseif(([regex]::matches($message.text, "(?i)rally"))[0].length -gt 0){
							if(([regex]::matches($message.text, "(?i)update"))[0].length -gt 0){
								if(([regex]::matches($message.text, "\w\w\d\d\d\d\d"))[0].length -gt 0){
									$input = [string]([regex]::matches($message.text, "\w\w\d\d\d\d\d"))[0]
									
									$turtle = .\turtlebot_rally.ps1 $input AutoIndirect
									if ($turtle -eq "err")
									{
										$response = "Couldn't do that for you, sorry. Input: $input"
									}
									else
									{
										## Call rallybot with 

										$rbInput = '"' +"$turtle $input"+'"'
										Write-host .\RallyBot.exe -buildid $rbInput
										$rb_output = .\RallyBot.exe -buildid $rbInput
										
										$response = "~sigh. I have updated your story with it's related build $turtle."
										

									}
								}else{
									
									$response = "If you want me to update rally, I need a story id. By the way, whoever named them 'stories' is a fool..."
								}
									
							}
						}
						
						
						if($response.length -gt 0){
							
							.\ParcelPirate.exe "<@$($message.user)> $response"				
						}				
					}#if user
				}#foreach message
			}#foreach parcel
		}# gross.. if
		
		mv slack\* slack_history\
		$parcels = ""
		$needed_arg = ""
		$json = ""
			
		echo 'waiting for new tasty parcels from humans...'

		Start-Sleep -s 10
		
	} while(1 -eq 1)
		
}


#begin
LoopProcess