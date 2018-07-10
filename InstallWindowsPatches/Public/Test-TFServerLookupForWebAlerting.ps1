function Test-TFServerLookupForWebAlerting
{
    <#
    .Synopsis
       Test to see if a server matches our mock database of servers to LogicMon Websites we monitor.
    .DESCRIPTION
       Use this function to test Web servers
    .EXAMPLE
       Test-TFServerIsSql -Verbose
    .EXAMPLE
       
    #>
    [CmdletBinding()]
    param
    (
        # ComputerName
        [Parameter(            
            ValueFromPipeline, 
            ValueFromPipelineByPropertyName
        )]
        [string[]]$ComputerName = $env:COMPUTERNAME
    )
    begin
    {
    }
    process
    {                        
        $lookupTable = @{
            'crp01mailflow01.paydayone.com' = 'mailflow.thinkfinance.com'
            'crp02arch04.think.local'       = 'rass.thinkfinance.com'
            'crp02itschgr02.think.local'    = 'servicedesk.thinkfinance.com'            
        }

        $ComputerName | ForEach-Object { $lookupTable[$_] }
    }
    end
    {
    }
}