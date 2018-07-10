function Invoke-TFSqlAvailabilityGroupMove
{
    <#
    .Synopsis
       Move an Availability Group
    .DESCRIPTION
       Use this function to safely failover a SQL Availability Group.
    .EXAMPLE
       $moveAgsResult = Invoke-TFSqlAvailabilityGroupMove -Session $session -Confirm:$false -Verbose
    .EXAMPLE
       
    #>
    [CmdletBinding(
        SupportsShouldProcess, 
        ConfirmImpact = 'High',
        DefaultParameterSetName = 'OnlySession'
    )]
    param
    (
        # PSSession to SQL Server
        [Parameter(
            Mandatory,
            ParameterSetName = 'OnlySession'
        )]
        [Parameter(
            Mandatory,
            ParameterSetName = 'SetBackOriginal'
        )]        
        [object]$Session,

        # Switch to set Availability Groups back to normal
        [Parameter(
            Mandatory, 
            ValueFromPipeline, 
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'SetBackOriginal'
        )]
        [switch]$SetAgBackToOriginal,

        # Availability Groups to move back
        [Parameter(
            Mandatory,             
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'SetBackOriginal'
        )]
        [string[]]$AvailabilityGroup,

        # SQL Ag Primary Node
        [Parameter(
            Mandatory,             
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'SetBackOriginal'
        )]
        [string]$PrimaryNode,

        # SQL Ag Secondary Node
        [Parameter(
            Mandatory,             
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'SetBackOriginal'
        )]
        [string]$SecondaryNode
    )
    begin
    {
    }
    process
    {
        if ($SetAgBackToOriginal)
        {
            if ($PSCmdlet.ShouldProcess("Move Availability Group from $SecondaryNode back to $PrimaryNode"))
            {
                if ($Session.State -ne 'Opened')
                {
                    Write-Error "Because the session state for $($Session.Name) $($Session.ComputerName) is not equal to Open, you cannot run a command in the session. The session state is $($Session.State)."
                    continue
                }

                $primaryNodeForMove = $SecondaryNode
                $secondaryNodeForMove = $PrimaryNode
                $agsToMove = $AvailabilityGroup
            }
        }
        else
        {
            if ($PSCmdlet.ShouldProcess("Move Availability Group from $($Session.ComputerName) to secondary node"))
            {
                if ($Session.State -ne 'Opened')
                {
                    Write-Error "Because the session state for $($Session.Name) $($Session.ComputerName) is not equal to Open, you cannot run a command in the session. The session state is $($Session.State)."
                    return
                }

                $agInfo = Invoke-Command -Session $Session -ScriptBlock ${function:Get-TFSqlAvailabilityGroup} -HideComputerName | Select-Object AvailabilityGroup, Node

                if (-not $agInfo.AvailabilityGroup)
                {
                    Write-Verbose "SQL AG: no SQL Availability Groups were found on $($Session.ComputerName)."
                    return
                }

                $computerShortName = $Session.ComputerName.Split('.')[0]
                $primaryNodeForMove = @($agInfo.Node.Name).Where( { $_ -like $computerShortName }) | Select-Object -Unique
                $secondaryNodeForMove = @($agInfo.Node.Name).Where( { $_ -notlike $computerShortName }) | Select-Object -Unique

                if (-not $secondaryNodeForMove)
                {
                    Write-Verbose "SQL AG: $($Session.ComputerName) only has one active node and requires a reboot."
                    foreach ($ag in $agInfo.AvailabilityGroup.Name)
                    {
                        $splatNewSqlServerObject = @{
                            ComputerName         = $Session.ComputerName
                            Status               = "SQL AG: $ag on $($Session.ComputerName) only has one active node and requires a reboot."
                            SqlError             = $false
                            SqlAvailabilityGroup = $ag                            
                            IsSql                = $true
                            PrimaryNode          = $primaryNodeForMove
                        }
                        $newSqlServerObject = New-TFSqlServerObject @splatNewSqlServerObject
                        $slackObject = $newSqlServerObject | Select-Object ComputerName, Date, Status
                        [void](Send-TFSlackMessage -InputObject $slackObject -Channel Patching -Notification Warning -Verbose)
                        $newSqlServerObject
                    }
                    return
                }
                $agsToMove = @($agInfo.AvailabilityGroup).Where( { $_.LocalReplicaRole -eq 'Primary' }).Name
            }  
        }
        
        if ($PSCmdlet.ShouldProcess("Moving Availability Group: $agsToMove"))
        {
            Write-Verbose "Moving Availability Group: $agsToMove"
            $splatInvokeCommand = @{
                Session          = $Session
                ScriptBlock      = ${function:Move-TFSqlAvailabilityGroup}
                ArgumentList     = $primaryNodeForMove, $agsToMove, $secondaryNodeForMove
                HideComputerName = $true
            }
            $moveAgsResult = Invoke-Command @splatInvokeCommand

            $agsMoved = @($moveAgsResult).Where( { -not $_.Error })
            $agsThatFailedToMove = @($moveAgsResult).Where( { $_.Error })

            if ($agsThatFailedToMove)
            {                
                foreach ($ag in $agsThatFailedToMove)
                {
                    Write-Verbose "An error occurred moving $($ag.AvailabilityGroup)."
                    $splatNewSqlServerObject = @{
                        ComputerName         = $Session.ComputerName
                        Status               = $ag.Status
                        SqlError             = $ag.Error
                        SqlAgSwitched        = $ag.SqlAgSwitched
                        SqlAvailabilityGroup = $ag.AvailabilityGroup                            
                        IsSql                = $true
                        PrimaryNode          = $primaryNodeForMove
                        SecondaryNode        = $secondaryNodeForMove
                    }
                    $newSqlServerObject = New-TFSqlServerObject @splatNewSqlServerObject
                    $slackObject = $newSqlServerObject | Select-Object ComputerName, Date, Status
                    [void](Send-TFSlackMessage -InputObject $slackObject -Channel Patching -Notification Error)
                    $newSqlServerObject
                }

                # the -not $SetAgBackToOriginal condition is to prevent an already moved Ag from getting moved back if some other Ag fails
                # e.g. Two Ags are moved, now two need to be moved back to their original location, one Ag fails to move back
                # we don't want to move the successful Ag back because the other one failed
                if ($agsMoved -and -not $SetAgBackToOriginal)
                {                    
                    Write-Verbose "Some AGs moved on $($session.ComputerName), but at least one failed. Setting everything back to original state."
                    $splatInvokeCommand = @{
                        Session          = $Session
                        ScriptBlock      = ${function:Move-TFSqlAvailabilityGroup}
                        ArgumentList     = $secondaryNodeForMove, $($agsMoved.SqlAvailabilityGroup), $primaryNodeForMove
                        HideComputerName = $true
                    }                                
                    [void](Invoke-Command @splatInvokeCommand)
                }
            }

            if ($agsMoved)
            {
                foreach ($ag in $agsMoved)
                {
                    $splatNewSqlServerObject = @{
                        ComputerName         = $Session.ComputerName
                        Status               = $ag.Status
                        SqlError             = $ag.Error
                        SqlAgSwitched        = $ag.SqlAgSwitched
                        SqlAvailabilityGroup = $ag.AvailabilityGroup                        
                        IsSql                = $true
                        PrimaryNode          = $primaryNodeForMove
                        SecondaryNode        = $secondaryNodeForMove
                    }
                    $newSqlServerObject = New-TFSqlServerObject @splatNewSqlServerObject
                    $slackObject = $newSqlServerObject | Select-Object ComputerName, Date, Status
                    [void](Send-TFSlackMessage -InputObject $slackObject -Channel Patching)
                    $newSqlServerObject
                }
            }
        }
    }
    end
    {
    }
}