function New-TFLogicMonHeader
{
    <#
    .Synopsis
       New Logic Monitor Header 
    .DESCRIPTION
       Use this function to build a new Logic Monitor header to authenticate with the Rest API
    .EXAMPLE
       $header = New-TFLogicMonHeader -AccessKey "AccessKey" -AccessId "AccessId" -Verb Get -Verbose
    .EXAMPLE
       $server = "devcaritsdc01.think.dev"
       $logicMonInfo = $server | Get-TFLogicMonLogin
       $header = $logicMonInfo[0] | New-TFLogicMonHeader -Verb Get -Verbose
    #>
    [CmdletBinding()]
    param
    (                
        # Access Key from LogicMon for your user account
        [parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$AccessKey,

        # Access ID from LogicMon for your user account
        [parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$AccessId,
        
        # HTTP Verb (Get, Post, Put, Delete)
        [parameter(Mandatory)]
        [ValidateSet("Get", "Post", "Put", "Delete")]
        [string]$Verb
    )
    begin
    {
    }
    process
    {        
        Write-Verbose "Defining account info for LogicMon."        
        $httpVerb = $Verb.ToUpper()

        Write-Verbose "Getting current time in milliseconds."
        $epoch = [Math]::Round((New-TimeSpan -start (Get-Date -Date "1/1/1970") -end (Get-Date).ToUniversalTime()).TotalMilliseconds)
        $requestVars = $httpVerb + $epoch + "/device/devices"
        
        Write-Verbose "Constructing signature"
        $hmac = New-Object System.Security.Cryptography.HMACSHA256
        $hmac.Key = [Text.Encoding]::UTF8.GetBytes($AccessKey)
        $signatureBytes = $hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($requestVars))
        $signatureHex = [System.BitConverter]::ToString($signatureBytes) -replace '-'
        $signature = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($signatureHex.ToLower()))
        
        Write-Verbose "Constructing header"
        $auth = 'LMv1 ' + $AccessId + ':' + $signature + ':' + $epoch
        $header = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $header.Add("Authorization", $auth)
        $header.Add("Content-Type", 'application/json')
        
        $header
    }
    end
    {
    }
}