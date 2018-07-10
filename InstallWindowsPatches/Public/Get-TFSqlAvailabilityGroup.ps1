function Get-TFSqlAvailabilityGroup
{
    <#
    .Synopsis
       Get SQL availability group information from a server
    .DESCRIPTION
       Use this function to get SQL availability group information for a server.
    .EXAMPLE
       
    .EXAMPLE
       
    #>
    [CmdletBinding()]
    param
    (

    )
    begin
    {
    }
    process
    {
        Import-Module SQLPS -ErrorAction Stop -WarningAction SilentlyContinue
        
        $availabilityGroups = Get-ChildItem SQLSERVER:\SQL\$env:COMPUTERNAME\DEFAULT\AvailabilityGroups
        
        if ($availabilityGroups)
        {
            [PSCustomobject] @{
                AvailabilityGroup = $availabilityGroups
                Node              = $availabilityGroups.AvailabilityReplicas
            }
        }        
    }
    end
    {
    }
}