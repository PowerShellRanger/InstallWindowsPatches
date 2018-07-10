
#Import my InstallWindowsPatches module from $env:psmodulepath
Import-Module InstallWindowsPatches -ErrorAction Stop

$date = Get-Date
$groupName = [string]$date.DayOfWeek + ' ' + 'Patch'
$domains = ''
$maxJobCount = 60
$failedServers = @()
$vCenters = ''
$null = Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Scope User -Confirm:$false
$vSession = Connect-VIServer -Server $vCenters -Credential (Get-AutomationPSCredential -Name 'CRP Automation Account')

if ($date.DayOfWeek -eq 'Saturday' -and $date.TimeOfDay.Hours -lt 20) 
{
    $servers = Get-TFServersInGroup -Domain '' -GroupName 'Saturday Patch EDW EIM'    
}
else
{
    $servers = Get-TFServersInGroup -Domain $domains -GroupName $groupName
}

foreach ($server in $servers)
{    
    if (-not (Test-Connection -ComputerName $server -Count 3 -Quiet -ErrorAction SilentlyContinue))
    {
        $offlineServer = New-TFPatchingObject -ComputerName $server -Status "Failed to establish a connection to $server" -PatchingError
        $slackObject = $offlineServer | Select-Object ComputerName, Date, Status
        [void](Send-TFSlackMessage -InputObject $slackObject -Channel Patching -Notification Error)
        $failedServers += $offlineServer
        continue
    }

    #loop to add jobs into the queue
    $waitForAPositionInQueue = $true
    while ($waitForAPositionInQueue)
    {
        $checkNumberJobsRunning = (Get-Job -State Running | Where-Object {$_.Name -like "Install Updates on *"}).Count
        #if number of running jobs is less than max allowed add another into the queue
        if ($checkNumberJobsRunning -lt $maxJobCount)
        {
            $jobName = "Install Updates on $server" 
            Write-Verbose "Starting job, $($jobName) to install Windows Patches on $server."
            $credentials = $server | Get-TFUsernamePass
            $null = Start-Job -Name $jobName -ScriptBlock {
                
                $WarningPreference = 'SilentlyContinue'
                $VerbosePreference = 'Continue'
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

                Import-Module InstallWindowsPatches -ErrorAction Stop

                $sqlServerOutput = New-Object System.Collections.ArrayList                
                
                $session = New-TFPSSession -ComputerName $using:server -Credential $using:credentials

                if ($session.State -ne 'Opened')
                {
                    $slackObject = $session | Select-Object ComputerName, Date, Status
                    [void](Send-TFSlackMessage -InputObject $slackObject -Channel Patching -Notification Error)
                    $session
                    break
                }

                Write-Verbose "First check for patches on: $($session.ComputerName)."
                $firstCheckForPatches = Invoke-Command -Session $session -ScriptBlock ${function:Get-TFWindowsPatches} -ArgumentList $session.ComputerName -HideComputerName

                if ($firstCheckForPatches.Updates -eq 0)
                {
                    #nothing to do...no updates to install. Exit all loops.
                    Write-Verbose "No patches found on: $($session.ComputerName)."
                    Remove-PSSession -Session $session -Confirm:$false
                    $firstCheckForPatches
                    break
                }

                if ($firstCheckForPatches.Error)
                {
                    Write-Verbose "An error occurred checking patches on: $($session.ComputerName)."
                    Write-Verbose "Error: $($firstCheckForPatches.Status)"
                    $slackObject = $firstCheckForPatches | Select-Object ComputerName, Date, Status
                    [void](Send-TFSlackMessage -InputObject $slackObject -Channel Patching -Notification Error)
                    Remove-PSSession -Session $session -Confirm:$false
                    $firstCheckForPatches
                    break
                }

                $pendingReboot = Get-TFRebootStatus -ComputerName $session.ComputerName -Session $session
                Write-Verbose "Checking for SQL on: $($session.ComputerName)."
                $checkForSql = Invoke-Command -Session $session -ScriptBlock ${function:Test-TFServerIsSql} -ArgumentList $session.ComputerName -HideComputerName

                if ($pendingReboot.RebootRequired)
                {
                    if ($checkForSql.IsSql)
                    {
                        $moveAgsResult = Invoke-TFSqlAvailabilityGroupMove -Session $session -Confirm:$false -Verbose

                        if ($moveAgsResult.Error -contains $true)
                        {
                            [void]$sqlServerOutput.Add($moveAgsResult)
                            $sqlServerOutput
                            Remove-PSSession -Session $session -Confirm:$false
                            break
                        }

                        if ($moveAgsResult.SqlAgSwitched -contains $true)
                        {
                            $agWasMovedForPatching = $true
                        }

                        [void]$sqlServerOutput.Add($moveAgsResult)
                    }                    

                    $splatLogicMonSdt = @{
                        ComputerName = $session.ComputerName
                        Duration     = 4
                        Comment      = 'In SDT for Patching'
                        Type         = 'DeviceSDT'
                        Confirm      = $false
                    }
                    $logicMonResponse = Set-TFLogicMonSdt @splatLogicMonSdt
                    
                    if ($checkForSql.IsSql -and $agWasMovedForPatching)
                    {
                        $splatLogicMonSdt['ComputerName'] = $($moveAgsResult[0].SecondaryNode)
                        $splatLogicMonSdt['Type'] = 'DeviceEventSourceSDT'
                        $splatLogicMonSdt['EventSourceName'] = 'Windows Clustering Events_2008'
                        $splatLogicMonSdt['Comment'] = "In SDT to patch partner node: $($session.ComputerName)"
                        [void](Set-TFLogicMonSdt @splatLogicMonSdt)
                    }

                    $fileShareWitnessNodes = Test-TFServerLookupFileShareWitness -ComputerName $session.ComputerName

                    if ($fileShareWitnessNodes)
                    {
                        foreach ($node in $fileShareWitnessNodes)
                        {
                            $splatLogicMonSdt['ComputerName'] = $node
                            $splatLogicMonSdt['Type'] = 'DeviceEventSourceSDT'
                            $splatLogicMonSdt['EventSourceName'] = 'Windows Clustering Events_2008'
                            $splatLogicMonSdt['Comment'] = "In SDT to patch partner node: $($session.ComputerName)"
                            [void](Set-TFLogicMonSdt @splatLogicMonSdt)
                        }
                    }

                    $slackObject = [PSCustomObject] @{
                        ComputerName = $session.ComputerName
                        Date         = (Get-Date -format MM\\dd\\yy-HH.mm)
                        Status       = "Rebooting Computer: $($session.ComputerName) before installing updates because of a pending reboot."
                    }
                    [void](Send-TFSlackMessage -InputObject $slackObject -Channel Patching -Notification Warning)

                    Write-Verbose "Rebooting Computer: $($session.ComputerName) before installing updates because of a pending reboot."
                    $restartResult = Restart-TFComputerForPatching -ComputerName $session.ComputerName -Credential $using:credentials -vSession $using:vSession -Confirm:$false
                    
                    if ($restartResult.Error)
                    {
                        $restartResult
                        break
                    }
                }

                $exitLoopAfter = New-TimeSpan -Hours 4
                $stopWatch = [diagnostics.stopwatch]::StartNew()
                                            
                while ((-not $serverPatchingComplete) -and ($stopWatch.Elapsed -le $exitLoopAfter))
                {
                    if ($session.State -ne 'Opened')
                    {
                        $session = New-TFPSSession -ComputerName $using:server -Credential $using:credentials
                    }
                    
                    $jobResults = Invoke-Command -Session $session -ScriptBlock ${function:Register-TFScheduledJobInstallPatches} -ArgumentList $session.ComputerName -HideComputerName                    
                    $jobResults

                    $notification = 'Succeeded'
                    if ($jobResults.Error) { $notification = 'Error' }                    
                    $slackObject = $jobResults | Select-Object ComputerName, Updates, Date, Duration, Status
                    [void](Send-TFSlackMessage -InputObject $slackObject -Channel Patching -Notification $notification)
                
                    if (($jobResults.Updates -gt 0) -and (-not $jobResults.Error) -and (-not $jobResults.RebootRequired))
                    {
                        Write-Verbose "$($jobResults.Updates) updates were installed on $($session.ComputerName). Doing another pass to see if anymore updates are available."
                        continue
                    }
                                        
                    if ($jobResults.RebootRequired -and $checkForSql.IsSql -and (-not $agWasMovedForPatching))
                    {
                        $moveAgsResult = Invoke-TFSqlAvailabilityGroupMove -Session $session -Confirm:$false -Verbose

                        if ($moveAgsResult.Error -contains $true)
                        {
                            [void]$sqlServerOutput.Add($moveAgsResult)
                            $sqlServerOutput
                            Remove-PSSession -Session $session -Confirm:$false
                            break
                        }

                        if ($moveAgsResult.SqlAgSwitched -contains $true)
                        {
                            $agWasMovedForPatching = $true
                        }
                        
                        [void]$sqlServerOutput.Add($moveAgsResult)                        
                    }

                    if ($jobResults.RebootRequired)
                    {                                                
                        if ($logicMonResponse.SDTScheduled -ne 'OK')
                        {
                            $splatLogicMonSdt = @{
                                ComputerName = $session.ComputerName
                                Duration     = 4
                                Comment      = 'In SDT for Patching'
                                Type         = 'DeviceSDT'
                                Confirm      = $false
                            }
                            $logicMonResponse = Set-TFLogicMonSdt @splatLogicMonSdt
                            
                            if ($checkForSql.IsSql -and $agWasMovedForPatching)
                            {
                                $splatLogicMonSdt['ComputerName'] = $($moveAgsResult[0].SecondaryNode)
                                $splatLogicMonSdt['Type'] = 'DeviceEventSourceSDT'
                                $splatLogicMonSdt['EventSourceName'] = 'Windows Clustering Events_2008'
                                $splatLogicMonSdt['Comment'] = "In SDT to patch partner node: $($session.ComputerName)"
                                [void](Set-TFLogicMonSdt @splatLogicMonSdt)
                            }

                            $fileShareWitnessNodes = Test-TFServerLookupFileShareWitness -ComputerName $session.ComputerName

                            if ($fileShareWitnessNodes)
                            {
                                foreach ($node in $fileShareWitnessNodes)
                                {
                                    $splatLogicMonSdt['ComputerName'] = $node
                                    $splatLogicMonSdt['Type'] = 'DeviceEventSourceSDT'
                                    $splatLogicMonSdt['EventSourceName'] = 'Windows Clustering Events_2008'
                                    $splatLogicMonSdt['Comment'] = "In SDT to patch partner node: $($session.ComputerName)"
                                    [void](Set-TFLogicMonSdt @splatLogicMonSdt)
                                }
                            }
                        }

                        $slackObject = [PSCustomObject] @{
                            ComputerName = $session.ComputerName
                            Date         = (Get-Date -format MM\\dd\\yy-HH.mm)
                            Status       = "Rebooting Computer: $($session.ComputerName) to finish installing $($jobResults.Updates) updates."
                        }
                        [void](Send-TFSlackMessage -InputObject $slackObject -Channel Patching -Notification Warning -Verbose)

                        Write-Verbose "Restarting Computer: $($session.ComputerName) to finish installing $($jobResults.Updates) updates."
                        $restartResult = Restart-TFComputerForPatching -ComputerName $session.ComputerName -Credential $using:credentials -vSession $using:vSession -Confirm:$false
                        
                        if ($restartResult.Error)
                        {
                            $restartResult
                            break
                        }
                    }

                    if ($agWasMovedForPatching)
                    {                                                
                        if ($session.State -ne 'Opened')
                        {
                            $session = New-TFPSSession -ComputerName $using:server -Credential $using:credentials
                        }
                        
                        Write-Verbose "Moving Availability Groups back to their original, pre-patching location: $($session.ComputerName)"
                        $splatInvokeTFSqlAvailabilityGroupMove = @{
                            Session             = $session
                            SetAgBackToOriginal = $true
                            AvailabilityGroup   = @($moveAgsResult).Where({ $_.SqlAgSwitched }).SqlAvailabilityGroup
                            PrimaryNode         = $moveAgsResult[0].PrimaryNode
                            SecondaryNode       = $moveAgsResult[0].SecondaryNode
                            Confirm             = $false
                        }                        
                        $moveAgsBackResult = Invoke-TFSqlAvailabilityGroupMove @splatInvokeTFSqlAvailabilityGroupMove -Verbose
                        [void]$sqlServerOutput.Add($moveAgsBackResult)
                    }

                    Remove-PSSession -Session $session -Confirm:$false
                    $serverPatchingComplete = $true
                }

                $sqlServerOutput
            }

            $waitForAPositionInQueue = $false
        }
    }
}

$localJobs = Get-Job -Name "Install Updates on *"
[void]($localJobs | Wait-Job -Timeout 7200)

$logPath = ''
foreach ($job in $localJobs)
{
    $verboseOutput = $job.ChildJobs.Verbose
    $computerName = $job.Name.Split(' ')[-1]
    $fileName = "patchingResults_$computerName.txt"
    $fullLogPath = Join-Path -Path $logPath -ChildPath $fileName
    Get-Date -format MM\\dd\\yy-HH.mm | Add-Content -Path $fullLogPath
    $verboseOutput | where { $_ -notlike "*Importing*" -and $_ -notlike "*Exporting*"} | Add-Content -Path $fullLogPath
    "`r`n" | Add-Content -Path $fullLogPath
}

$receivedJobs = $localJobs | Receive-Job
$localJobs | Remove-Job
$receivedJobs

Disconnect-VIServer -Server $vSession -Confirm:$false

$patchJobSummary = [PSCustomObject] @{
    'Servers Attempted to Patch:'             = $servers.Count
    'Successes:'                              = @($receivedJobs).Where( { $_.Status -eq 'Succeeded' }).Count
    'Servers that do not need to be Patched:' = @($receivedJobs).Where( { $_.Updates -eq 0 }).Count
    'Failures:'                               = @($receivedJobs).Where( { $_.Error }).Count + $failedServers.Count
}
[void](Send-TFSlackMessage -InputObject $patchJobSummary -Channel Patching -Notification Summary -Verbose)

$serversThatFailed = @()
foreach ($receivedJobWithError in ($receivedJobs | Where-Object {$_.Error}))
{
    foreach ($failedPatch in $receivedJobWithError.Status)
    {
        $serversThatFailed += [PSCustomObject] @{
            ComputerName = $receivedJobWithError.ComputerName | Select-Object -Unique
            ErrorMessage = $failedPatch
        }
    }
}

foreach ($failedServer in $failedServers)
{
    $serversThatFailed += [PSCustomObject] @{
        ComputerName = $failedServer.ComputerName
        ErrorMessage = $failedServer.Status
    }
}

$preContent = "Failed to patch the following servers. Please remediate."
$htmlFragment = ConvertTo-TFHtmlFragment -InputObject $serversThatFailed -PreContent "<h4>+ $preContent </h4>"
$subject = "Post Patch Summary for " + $date.ToShortDateString()
$convertToHtmlSplat = @{
    HTMLFragment = @($htmlFragment)    
    PreContent   = "<H1>$subject</H1>"
    PostContent  = "Created $(Get-Date)"
    Title        = 'Post Patch Summary' 
}

$smtpServer = ''
$fromAddress = ''
$toAddress = ''

$emailText = ConvertTo-TFHtml @convertToHtmlSplat | Out-String
Send-MailMessage -From $fromAddress -To $toAddress -Subject $subject -Body $emailText -BodyAsHtml -SmtpServer $smtpServer

$patchingResultsMonth = (Get-Culture).DateTimeFormat.GetAbbreviatedMonthName($date.Month)
$patchingResultsCsvPath = ''
$patchingResultsCsv = Get-Item -Path $patchingResultsCsvPath -ErrorAction SilentlyContinue

if (-not ($patchingResultsCsv -or $patchingResultsCsv.CreationTime.Month -eq $date.Month))
{
    $receivedJobs | Where-Object {$_.ComputerName -notlike $null} | Select-Object ComputerName, Updates, RebootRequired, Date, Duration, Status, PatchingError | Export-Csv -Path $patchingResultsCsvPath -NoTypeInformation
}
else
{
    $receivedJobs | Where-Object {$_.ComputerName -notlike $null} | Select-Object ComputerName, Updates, RebootRequired, Date, Duration, Status, PatchingError | Export-Csv -Path $patchingResultsCsvPath -Append -NoTypeInformation -Force
}

