function Move-TFSqlAvailabilityGroup
{
    <#
    .Synopsis
       Move an Availability Group
    .DESCRIPTION
       Use this function to move an Availability Group to another node.
    .EXAMPLE
       
    .EXAMPLE
       
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        # ComputerName
        [Parameter(Mandatory)]
        [string]$ComputerName,

        # AvailabilityGroup
        [Parameter(Mandatory)]
        [string[]]$AvailabilityGroup,

        # Node to move Availability Group to        
        [Parameter(Mandatory)]
        [string]$SecondaryNode
    )
    begin
    {
        Import-Module SQLPS -ErrorAction Stop -WarningAction SilentlyContinue
    }
    process
    {
        foreach ($ag in $AvailabilityGroup)
        {
            if ($PSCmdlet.ShouldProcess("Moving $ag from $ComputerName to $SecondaryNode."))
            {
                Write-Verbose "Testing AG: $ag to make sure it is safe to failover."
                while (-not (Get-ChildItem -Path "SQLSERVER:\Sql\$ComputerName\DEFAULT\AvailabilityGroups\$ag\AvailabilityDatabases").IsFailoverReady)
                {
                    Write-Verbose "Waiting 30 seconds for AG: $ag on ComputerName: $ComputerName to synchronize."
                    Start-Sleep 30    
                }
                
                try 
                {
                    Write-Verbose "Moving $ag from $ComputerName to $SecondaryNode."
                    $splatSqlAgSwitch = @{
                        Path        = "SQLSERVER:\Sql\$($SecondaryNode)\DEFAULT\AvailabilityGroups\$($ag)"                        
                        Confirm     = $false
                        ErrorAction = 'Stop'
                    }
                    Switch-SqlAvailabilityGroup @splatSqlAgSwitch
                    
                    $status = "Successfully moved $ag from $ComputerName to $SecondaryNode."
                    $patchingError = $false
                    $sqlAgSwitched = $true
                }
                catch
                {
                    $status = $_.Exception.Message
                    $patchingError = $true
                    $sqlAgSwitched = $false
                }

                [PSCustomObject] @{
                    ComputerName      = $ComputerName          
                    Status            = $status                
                    Error             = $patchingError
                    SqlAgSwitched     = $sqlAgSwitched
                    AvailabilityGroup = $ag
                }                
            }
        }
    }
    end
    {
    }
}