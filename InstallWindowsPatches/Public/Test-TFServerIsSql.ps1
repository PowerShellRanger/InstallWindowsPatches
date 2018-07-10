function Test-TFServerIsSql
{
     <#
    .Synopsis
       Test to see if a server has SQL installed
    .DESCRIPTION
       Use this function to test for SQL servers
    .EXAMPLE
       Test-TFServerIsSql -Verbose
    .EXAMPLE
       
    #>
    [CmdletBinding()]
    param
    (
        # ComputerName
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$ComputerName       
    )
    begin
    {
    }
    process
    {                        
        Import-Module SQLPS -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        
        $isSql = $false
        
        Write-Verbose "Testing Path: SQLSERVER:\SQL\$env:COMPUTERNAME\DEFAULT"
        if (Test-Path SQLSERVER:\SQL\$env:COMPUTERNAME\DEFAULT -ErrorAction SilentlyContinue)
        {
            $isSql = $true    
        }
       
        [PSCustomObject] @{
            ComputerName = [System.Net.Dns]::GetHostByName((hostname)).HostName
            IsSql        = $isSql
        }        
    }
    end
    {
    }
}