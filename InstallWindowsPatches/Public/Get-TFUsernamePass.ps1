function Get-TFUsernamePass
{
    <#
    .Synopsis
       Get username and password for each domain.
    .DESCRIPTION
       Get username and password for each domain.
    .EXAMPLE
       
    .EXAMPLE
       
    #>
    [CmdletBinding()]
    Param
    (
        # Server must be FQDN to get domain creds
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [string[]]$ComputerName
    )
    begin
    {
    }
    process
    {
        foreach ($server in $ComputerName) 
        {
            Write-Verbose "Getting Credentials for $($server)."
            $domain = $server.Split(".")[-2, -1] -join "."
            Write-Verbose "Looking up Credentials for $domain."
            switch ($domain)
            {
                {$_ -like "*.dev"} {$credential = Get-AutomationPSCredential -Name 'DEV Automation Account'}
                {$_ -like "*.local"} {$credential = Get-AutomationPSCredential -Name 'PRD Automation Account'}
                {$_ -like "*.com"} {$credential = Get-AutomationPSCredential -Name 'PDO Automation Account'}
                default {$credential = Get-AutomationPSCredential -Name 'CRP Automation Account'}
            }
            $credential
        }                
    }
    end
    {
    }
}