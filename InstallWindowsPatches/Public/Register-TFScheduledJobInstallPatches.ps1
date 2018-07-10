function Register-TFScheduledJobInstallPatches
{
    <#
    .Synopsis
        Install Windows Patches and return results.
    .DESCRIPTION
        Use this function to install Windows Patches and return the results.
    .EXAMPLE

    .EXAMPLE
       
    #>
    [CmdletBinding()]
    Param
    (
        # ComputerName
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$ComputerName        
    )
    begin
    {        
    }
    process
    {                
        $dateAndTimeJobFormated = Get-Date -format ddMMMyyyy-HH.mm
        try
        {
            $job = Register-ScheduledJob -Name "InstallUpdates $dateAndTimeJobFormated" -ArgumentList $ComputerName -RunNow -ScriptBlock {
                Param
                (                    
                    $ComputerName
                )
                $dateAndTime = Get-Date -format MM\\dd\\yy-HH.mm                        
                $scriptStart = Get-Date
                $criteria = "IsInstalled=0 and Type='Software'"
                $searchResult = (New-Object -ComObject Microsoft.Update.Searcher).Search($criteria).Updates
                if ($searchResult.Count -eq 0)
                {
                    $updates = $searchResult.Count
                    $rebootRequired = $false                    
                    $duration = 0
                    $status = "No Updates Available"
                    $patchingError = $false
                }
                else
                {
                    $session = New-Object -ComObject Microsoft.Update.Session
                    $downloader = $session.CreateUpdateDownloader()                        
                    $downloader.Updates = $searchResult
                    [void]($downloader.Download())
                    $installer = $session.CreateUpdateInstaller()                        
                    $installer.Updates = $searchResult
                    $installResults = $installer.Install()
                    $scriptEnd = Get-Date
                    $runTime = New-Timespan -Start $scriptStart -End $scriptEnd
                    if ($installResults.ResultCode -ne 2)
                    {                                                
                        $patchingError = $true        
                        $searcher = $session.CreateUpdateSearcher()
                        $failedPatches = @($searcher.QueryHistory(0, $searchResult.Count) | where {$_.ResultCode -ne 2})
                        $status = (Get-EventLog -LogName System -Source Microsoft-Windows-WindowsUpdateClient -EntryType Error -Newest $failedPatches.Count).Message
                    }
                    else
                    {                                                
                        $status = "Succeeded"
                        $patchingError = $false
                    }
                    $rebootRequired = $installResults.RebootRequired                                             
                    $updates = $searchResult.Count
                    $duration = '{0}:{1}:{2}' -f $runTime.Hours, $runTime.Minutes, $runTime.Seconds
                }
                [PSCustomObject] @{
                    ComputerName   = $($ComputerName)
                    Updates        = $($updates)
                    RebootRequired = $rebootRequired                            
                    Date           = $dateAndTime
                    Duration       = $duration
                    Status         = $status                            
                    Error          = $patchingError                    
                }
            } -ErrorAction Stop
        }
        catch
        {
            $errorMessage = $_.Exception.Message
            [PSCustomObject] @{
                ComputerName = $($ComputerName)
                Date         = (Get-Date -format MM\\dd\\yy-HH.mm)
                Status       = $errorMessage
                Error        = $true
            }
            return                            
        }

        Start-Sleep -Seconds 60                        
        
        Write-Verbose "Waiting job $($job.Name) to complete."
        [void](Wait-Job -Name $job.Name -Timeout 7200)

        try
        {                
            Write-Verbose "Receiving job $($job.Name)."
            $receivedJob = Receive-Job -Name $job.Name -ErrorAction Stop                
        }
        catch
        {
            $errorMessage = $_.Exception.Message
            [PSCustomObject] @{
                ComputerName = $($ComputerName)
                Date         = (Get-Date -format MM\\dd\\yy-HH.mm)
                Status       = $errorMessage
                Error        = $true
            }                
            return
        }
        
        Write-Verbose "Removing job $($job.Name)."
        $job.Remove('force')
        
        return $receivedJob
    }
    end
    {
    }
}

