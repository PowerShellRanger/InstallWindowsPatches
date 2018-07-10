function Get-TFRebootStatus
{
    <#
    .Synopsis
       Check to see if a reboot is pending
    .DESCRIPTION
       Use this function to checkfor pending reboots on a ComputerName.
    .EXAMPLE
       
    .EXAMPLE
       
    #>
    [CmdletBinding()]
    Param
    (
        # ComputerName
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string]$ComputerName,

        # PSSession
        [Parameter(Mandatory=$true)]
        [object]$Session
    )
    begin
    {        
    }
    process
    {        
        Write-Verbose "Remotely checking on $($ComputerName) for pending reboots."
        $functionResults = Invoke-Command -Session $Session -ScriptBlock {                             
            $registryRebootKey = Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction SilentlyContinue
            if ($registryRebootKey) {
                $rebootRequired = $true
            }
            else {
                $rebootRequired = $false
            }
            [PSCustomObject] @{
                ComputerName = $($using:ComputerName)
                Date = (Get-Date -format MM\\dd\\yy-HH.mm)
                RebootRequired = $rebootRequired
            }                            
        }                        
        $functionResults
    }
    end
    {
    }
}