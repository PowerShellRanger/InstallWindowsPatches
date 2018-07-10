function Send-TFSlackMessage
{
    <#
    .Synopsis
       Send slack message
    .DESCRIPTION
       Use this function to send messages to slack
    .EXAMPLE
       
    .EXAMPLE
       
    #>
    [CmdletBinding()]
    param
    (
        # InputObject to be displayed in slack
        [Parameter(Mandatory)]        
        [object[]]$InputObject,

        # Channel
        [Parameter(Mandatory)]
        [string]$Channel,        

        # Notification type determines color in slack
        [Parameter()]
        [ValidateSet('Warning', 'Error', 'Complete', 'Succeeded', 'Summary')]
        [string]$Notification = 'Complete'

    )
    begin
    {
        if (-not (Get-Module -Name PSSlack -ErrorAction SilentlyContinue))
        {
            Write-Verbose 'Import module PSSlack'
            Import-Module -Name PSSlack -ErrorAction Stop                
        }
    }
    process
    {        
        $uri = ''
        foreach ($object in $InputObject)
        {
            $fields = @()
            foreach ($prop in $object.psobject.Properties.Name)
            {
                $short = $false
                if (-not ($prop -eq "Status"))
                {
                    $short = $true
                }
                $fields += @{
                    title = $prop
                    value = $object.$prop
                    short = $short
                }
            }                                

            $colorLookupTable = @{
                Warning   = '#FFA500' #orange
                Error     = '#FF0000' #red
                Complete  = '#008000' #green
                Succeeded = '#0000FF' #blue
                Summary   = '#800080' #purple
            }

            $title = "Patching results for $($object.ComputerName)"
            
            if ($PSBoundParameters.ContainsValue('Summary'))
            {
                $date = Get-Date -Format MM\\d\\yy
                $title = "Patching summary for $date"
                $emoji = ':pushpin:'
                Write-Verbose "Sending summary message to Slack Channel $Channel." 
                New-SlackMessageAttachment -Color $colorLookupTable[$Notification] -Title $title -Fields $fields -Fallback "Your client does not support rich Messages!" |
                    New-SlackMessage -Channel $Channel -IconEmoji $emoji | Send-SlackMessage -Uri $uri
                continue
            }                        
            
            Write-Verbose "Sending message to Slack Channel: $Channel with updates for Computer: $($object.ComputerName)."
            New-SlackMessageAttachment -Color $colorLookupTable[$Notification] -Title $title -Fields $fields -Fallback "Your client does not support rich Messages!" |
                New-SlackMessage -Channel $Channel | Send-SlackMessage -Uri $uri
        }        
    }
    end
    {
    }
}