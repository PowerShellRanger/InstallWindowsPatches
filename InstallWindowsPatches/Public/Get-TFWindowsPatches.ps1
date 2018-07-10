function Get-TFWindowsPatches
{
    <#
    .Synopsis
        Get Windows Patches and return results.
    .DESCRIPTION
        Use this function to get how many Windows Patches are available and return the results.
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
        $criteria = "IsInstalled=0 and Type='Software'"        
        try
        {
            Write-Verbose "Creating new object to search for updates."
            $searchResults = (New-Object -ComObject Microsoft.Update.Searcher -ErrorAction Stop).Search($criteria).Updates
            $definitionUpdatesCount = @($searchResults | where {$_.Title -like 'Definition Update*'}).Count
            Write-Verbose "Building a new object with the searcher results to return to the pipeline."
            [PSCustomObject] @{
                ComputerName      = $ComputerName
                Date              = (Get-Date -format MM\\dd\\yy-HH.mm)
                Updates           = ($searchResults.count - $definitionUpdatesCount)
                Error             = $false
                IndividualUpdates = @(
                    foreach ($searchResult in $searchResults)
                    {
                        if ($searchResult.Title -like 'Definition Update*')
                        {
                            continue
                        }
                        [PSCustomObject] @{                        
                            KB               = 'KB' + $($searchResult.KBArticleIDs)                                
                            RebootRequired   = $($searchResult.RebootRequired)
                            Published        = $($searchResult.LastDeploymentChangeTime.ToShortDateString())
                            Title            = $($searchResult.Title)
                            PreviouslyFailed = (Get-EventLog -LogName System -Source Microsoft-Windows-WindowsUpdateClient -EntryType Error -Message "*KB$($searchResult.KBArticleIDs)*" -ErrorAction SilentlyContinue).Count
                        }
                    }
                )
            }
        }
        catch
        {
            Write-Warning "Something went wrong while searching for updates on $ComputerName."
            [PsCustomObject] @{
                ComputerName = $ComputerName
                Date         = (Get-Date -format MM\\dd\\yy-HH.mm)
                Status       = $_
                Error        = $true
            }
        }                        
    }
    end
    {
    }
}