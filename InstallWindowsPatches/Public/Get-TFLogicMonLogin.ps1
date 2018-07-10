function Get-TFLogicMonLogin
{
    <#
    .Synopsis
       Get Logic Monitor login creds and url.
    .DESCRIPTION
       Get Logic Monitor login creds and url.
    .EXAMPLE
       $server = "devcaritsdc01.think.dev"
       $logicMonInfo = Get-TFLogicMonLogin -ComputerName $server
    .EXAMPLE
       
    #>
    [CmdletBinding()]
    param
    (
        # Server must be FQDN to get LogicMon login info
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
            $domain = $server.Split(".")[-2, -1] -join "."
            $lleLogicMon = @{
                Company   = 'thinklle'
                AccessKey = Get-AutomationVariable -Name 'LleLogicMonToken'                
                AccessId  = 'R8PFhZ48869NU48NdC2y'
            }
            $prodLogicMon = @{
                Company   = 'thinkfinance'
                AccessKey = Get-AutomationVariable -Name 'ProdLogicMonToken'
                AccessId  = 'Zg6hf2Q9rfx2CPI9Mi5t'
            }            
            if ($domain -eq 'think.dev')
            {
                $arrayOfObjects = @(
                    [PSCustomObject] @{
                        Company   = $lleLogicMon.Company
                        AccessKey = $lleLogicMon.AccessKey
                        AccessId  = $lleLogicMon.AccessId
                    }
                    [PSCustomObject] @{
                        Company   = $prodLogicMon.Company
                        AccessKey = $prodLogicMon.AccessKey
                        AccessId  = $prodLogicMon.AccessId
                    }
                )
                Write-Output $arrayOfObjects
                continue
            }            
            $singleProdObject = [PSCustomObject] @{
                Company   = $prodLogicMon.Company
                AccessKey = $prodLogicMon.AccessKey
                AccessId  = $prodLogicMon.AccessId
            }                         
            Write-Output $singleProdObject
        }        
    }
    end
    {
    }
}