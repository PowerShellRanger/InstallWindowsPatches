function New-TFPatchingObject
{
    <#
    .Synopsis
        Build new object for patching results
    .DESCRIPTION
        Use this function to build a new object for results when installing Windows Patches.
    .EXAMPLE
        New-TFPatchingObject -ComputerName "some ComputerName" -Date (Get-Date -format MM\\dd\\yy-HH.mm) -Status "current status or error" -PatchingError $true or $false
    .EXAMPLE
        Splatting parameters to the object:
        $splat = @{
            ComputerName = $result.ComputerName
            Updates = $result.Updates
            RebootRequired = $result.RebootRequired
            Date = $result.Date
            Duration = $result.Duration
            Status = $result.Status
            PatchingError = $result.Error
        }
        New-TFPatchingObject @splat
    #>
    [OutputType('TfPatching.Object')]
    [CmdletBinding()]
    param
    (
        # ComputerName
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$ComputerName,

        # Updates
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]$Updates,

        # RebootRequired
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [switch]$RebootRequired,
        
        # Date
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Date = (Get-Date -format MM\\dd\\yy-HH.mm),
        
        # Duration
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Duration,

        # Status
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Status,

        # PatchingError
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [switch]$PatchingError,

        # SQL Availability Group switched to secondary node
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [switch]$SqlAgSwitched,

        # Availability Group and Node details
        [Parameter()]
        [object]$SqlAgDetails
    )
    begin
    {
    }
    process
    {
        [PSCustomObject] @{
            PSTypeName     = 'TfPatching.Object'
            ComputerName   = $ComputerName
            Updates        = $Updates
            RebootRequired = $RebootRequired
            Date           = $Date
            Duration       = $Duration
            Status         = $Status
            Error          = $PatchingError
            SqlAgSwitched  = $SqlAgSwitched
            SqlAgDetails   = $SqlAgDetails
        }                
    }
    end
    {
    }
}