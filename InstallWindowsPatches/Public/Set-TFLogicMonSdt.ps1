function Set-TFLogicMonSdt
{
    <#
    .Synopsis
        Set Scheduled Down Time for Servers in LogicMon's portal.
    .DESCRIPTION
        Use this function to set SDT's for one or multiple servers.
    .EXAMPLE
        $servers = "devcaritsdc01.think.dev" , "devcaritsdc02.think.dev"
        $servers | Set-TFLogicMonSdt -Duration 1 -Comment "test" -Verbose -confirm:$false
    .EXAMPLE
        Set-TFLogicMonSdt -ComputerName (Get-ADComputer -Filter 'Name -like "crpwacitsvbrp0*"' -Server think.local).DNSHostName -Duration 3
    .EXAMPLE
        $server = "devcaritsdc01.think.dev"
        Set-TFLogicMonSdt -ComputerName $server -Duration 1 -Comment "test" -Verbose -confirm:$false
    #>
    [CmdletBinding(
        SupportsShouldprocess,
        ConfirmImpact = "High")]
    param
    (
        # Name of device
        [Parameter(
            Mandatory, 
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [string[]]$ComputerName,

        # SDT Duration
        [Parameter(
            Mandatory, 
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [int]$Duration,
        
        # Why are you putting this device into SDT?
        [Parameter(
            Mandatory, 
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [string]$Comment,

        # Type of SDT this will be
        [Parameter(
            Mandatory, 
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [ValidateSet('DeviceSDT' , 'DeviceEventSourceSDT')]
        [string]$Type
    )

    DynamicParam 
    {
        if ($Type -eq 'DeviceEventSourceSDT')
        {
            Write-Verbose 'Create a new ParameterAttribute Object.'
            $eventSourceNameAttribute = New-Object System.Management.Automation.ParameterAttribute
            $eventSourceNameAttribute.Mandatory = $true
            $eventSourceNameAttribute.ValueFromPipeline = $true
            $eventSourceNameAttribute.ValueFromPipelineByPropertyName = $true
            Write-Verbose 'Create an attributecollection object for the attribute just created.'
            $attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $attributeCollection.Add($eventSourceNameAttribute)
            $eventSourceNameParam = New-Object System.Management.Automation.RuntimeDefinedParameter('EventSourceName', [string], $attributeCollection)
            $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $paramDictionary.Add('EventSourceName', $eventSourceNameParam)
            return $paramDictionary
        }
    }
    begin
    {
    }
    process
    {        
        foreach ($server in $ComputerName)
        {
            if ($PSCmdlet.Shouldprocess("Scheduled Down Time for $server will be set to $Duration."))
            {
                $device = $server | Get-TFLogicMonDevice

                if (-not $device.DeviceId)
                {
                    Write-Warning "$server was not found in LogicMonitor."
                    continue
                }

                $server = $server.split('.')[0]
                Write-Verbose "Defining account info for LogicMon."
                $httpVerb = "POST"
                
                Write-Verbose "Getting current time in milliseconds."
                $epoch = [Math]::Round((New-TimeSpan -start (Get-Date -Date "1/1/1970") -end (Get-Date).ToUniversalTime()).TotalMilliseconds)                                
                $endDateTime = [Math]::Round((New-TimeSpan -start (Get-Date -Date "1/1/1970") -end (Get-Date).ToUniversalTime().AddHours($Duration)).TotalMilliseconds)
                Write-Verbose "Building hash table to send to LogicMon."
                $data = @{
                    sdtType         = 1
                    type            = $Type
                    deviceId        = $($device.DeviceId)                    
                    comment         = $Comment
                    startDateTime   = $epoch
                    endDateTime     = $endDateTime
                }

                if ($PSBoundParameters.ContainsValue('DeviceEventSourceSDT'))
                {
                    $data['eventSourceName'] = $PSBoundParameters.EventSourceName
                }

                $url = "https://" + $($device.Company) + ".logicmonitor.com/santaba/rest" + "/sdt/sdts"
                $requestVars = $httpVerb + $epoch + ($data | ConvertTo-Json) + "/sdt/sdts"
                Write-Verbose "Constructing signature"
                $hmac = New-Object System.Security.Cryptography.HMACSHA256
                $hmac.Key = [Text.Encoding]::UTF8.GetBytes($($device.AccessKey))
                $signatureBytes = $hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($requestVars))
                $signatureHex = [System.BitConverter]::ToString($signatureBytes) -replace '-'
                $signature = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($signatureHex.ToLower()))
                Write-Verbose "Constructing headers"
                $auth = 'LMv1 ' + $($device.AccessId) + ':' + $signature + ':' + $epoch
                $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
                $headers.Add("Authorization", $auth)
                $headers.Add("Content-Type", 'application/json')
                try
                {
                    Write-Verbose "Attempting to post hash table to LogicMon's Api."
                    $responsePost = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body ($data | ConvertTo-Json) -ErrorAction Stop
                }
                catch
                {
                    Write-Verbose "Something went wrong while attempting to post to LogicMon's api"
                    throw $_
                }
                [PSCustomObject] @{
                    ServerName   = $server
                    SDTScheduled = $responsePost.errmsg                    
                }                
            }
        }
    }
    end
    {
    }
}