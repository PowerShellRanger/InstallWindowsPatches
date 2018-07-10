function New-TFSqlServerObject
{
    <#
    .Synopsis
        
    .DESCRIPTION
        
    .EXAMPLE
        
    .EXAMPLE        
    #>
    [OutputType('TfSqlServer.Object')]
    [CmdletBinding()]
    param
    (
        # ComputerName
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$ComputerName,

        # Status
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Status,

        # SqlError - something went wrong SQL related
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [switch]$SqlError,

        # SQL Availability Group switched to secondary node
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [switch]$SqlAgSwitched,

        # Availability Group and Node details
        [Parameter()]
        [string]$SqlAvailabilityGroup,

        # Switch for IsSql or Not
        [Parameter()]
        [switch]$IsSql,

        # SQL Ag Primary Node
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$PrimaryNode,

        # SQL Ag Secondary Node
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$SecondaryNode,

        # Date
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Date = (Get-Date -format MM\\dd\\yy-HH.mm)
    )
    begin
    {
    }
    process
    {
        [PSCustomObject] @{
            PSTypeName           = 'TfSqlServer.Object'
            ComputerName         = $ComputerName            
            Status               = $Status
            Error                = $SqlError
            SqlAgSwitched        = $SqlAgSwitched
            SqlAvailabilityGroup = $SqlAvailabilityGroup
            IsSql                = $IsSql
            PrimaryNode          = $PrimaryNode
            SecondaryNode        = $SecondaryNode
            Date                 = $Date
        }                
    }
    end
    {
    }
}