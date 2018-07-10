function Restart-TFComputerForPatching
{
    <#
    .Synopsis
       Restart a computer because of a pending reboot.
    .DESCRIPTION
       Restart a computer because of a pending reboot.
    .EXAMPLE
       
    .EXAMPLE
       
    #>
    [CmdletBinding(SupportsShouldprocess,
        ConfirmImpact = "High")]
    param
    (
        # Server must be FQDN to get domain creds
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$ComputerName,

        # Credential variable
        [Parameter(Mandatory)]
        [PSCredential]$Credential,
        
        # vCenter Session to reset hung VMs
        [Parameter()]
        [object]$vSession
    )
    begin
    {
    }
    process
    {
        if ($PSCmdlet.Shouldprocess($ComputerName))
        {
            try
            {
                Restart-Computer -ComputerName $ComputerName -Credential $Credential -Protocol WSMan -Force -Wait -For WinRM -Timeout 1200 -Delay 2 -ErrorAction Stop
                $patchingError = $false
            }
            catch [Microsoft.PowerShell.Commands.RestartComputerTimeoutException]
            {
                $WarningPreference = 'SilentlyContinue'

                Import-Module VMware.VimAutomation.Core -ErrorAction Stop -Force
                
                $null = Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Scope User -Confirm:$false                
                
                $session = @()
                foreach ($vcenter in $vSession)
                {
                    $session += Connect-VIServer -Server $vcenter.ServiceUri.Host -Session $vCenter.SessionId
                }
                
                $vm = Get-VM -Name "$($ComputerName.Split('.')[0])*" -ErrorAction Stop
                $vm.ExtensionData.ResetVM()
                $restartErrorMessage = "$ComputerName had to be manually reset from vCenter."
                $patchingError = $true
            }
            catch
            {
                $restartErrorMessage = $_.Exception.Message
                $patchingError = $true
            }            
            $output = New-TFPatchingObject -ComputerName $ComputerName -Status $restartErrorMessage -PatchingError:$patchingError
        }
        $output
    }
    end
    {
    }
}