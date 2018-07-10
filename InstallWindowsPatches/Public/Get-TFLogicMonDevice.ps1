function Get-TFLogicMonDevice
{
    <#
    .Synopsis
       Get a device from Logic Monitor.
    .DESCRIPTION
       Use this function to get devices from Logic Monitor.
    .EXAMPLE
       $server = "devcaritsdc01.think.dev"
       $header = New-TFLogicMonHeader -AccessKey "AccessKey" -AccessId "AccessId" -Verb Get -Verbose
       Get-TFLogicMonDevice -ComputerName $server -Verbose
    .EXAMPLE
       
    #>
    [CmdletBinding()]
    param
    (
        # Name of device
        [parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName
    )
    begin
    {
    }
    process
    {
        foreach ($server in $ComputerName)
        {
            Write-Verbose "Getting LogicMon login information."
            $logicMonLogins = $server | Get-TFLogicMonLogin
            $logicMonLoginsIndex = 0
            $serverNameSplit = $server.split('.')[0]            
            Write-Verbose "Building URL for Invoke-RestMethod cmdlet."
            $url = "https://" + $($logicMonLogins[$logicMonLoginsIndex].Company) + ".logicmonitor.com/santaba/rest" + "/device/devices?filter=displayName~$serverNameSplit"
            Write-Verbose "Building a new LogicMon header."
            $header = $logicMonLogins[$logicMonLoginsIndex] | New-TFLogicMonHeader -Verb Get            
            try
            {
                Write-Verbose "Trying to get data from LogicMon's rest API."               
                $response = Invoke-RestMethod -Uri $url -Method Get -Header $header -ErrorAction Stop
            }
            catch
            {
                throw $_
            }
            if ($response.data.total -ne 1 -and $logicMonLogins.count -gt 1)
            {
                $logicMonLoginsIndex = 1
                $url = "https://" + $($logicMonLogins[$logicMonLoginsIndex].Company) + ".logicmonitor.com/santaba/rest" + "/device/devices?filter=displayName~$serverNameSplit"
                $header = $logicMonLogins[$logicMonLoginsIndex] | New-TFLogicMonHeader -Verb Get                
                try
                {  
                    Write-Verbose "Trying to get data from LogicMon's rest API."                  
                    $response = Invoke-RestMethod -Uri $url -Method Get -Header $header -ErrorAction Stop
                }
                catch
                {
                    throw $_
                }
            }
            $output = [PSCustomObject] @{
                Name      = $($response.data.items.name)
                DeviceId  = $($response.data.items.id)
                Company   = $($logicMonLogins[$logicMonLoginsIndex].Company)
                AccessId  = $($logicMonLogins[$logicMonLoginsIndex].AccessId)
                AccessKey = $($logicMonLogins[$logicMonLoginsIndex].AccessKey)        
            }
            Write-Output $output
        }
    }
    end
    {
    }
}
