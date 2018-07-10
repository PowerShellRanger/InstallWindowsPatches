function New-TFPSSession
{
    <#
    .Synopsis
        Create a new PSSession to the list of computer names provide
    .DESCRIPTION
        Use this function to create a new PSSession to the list of computer names provide.
    .EXAMPLE

    .EXAMPLE
       
    #>
    [CmdletBinding()]
    Param
    (
        # ComputerName
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$ComputerName,

        # Credential variable
        [Parameter(Mandatory = $true)]
        [PSCredential]$Credential
    )
    begin
    {        
    }
    process
    {
        foreach ($computer in $ComputerName)
        {
            try
            {
                Write-Verbose "Establishing a new session to $($computer)."
                $sessionTimeOut = New-PSSessionOption -OpenTimeout 300000
                New-PSSession -ComputerName $computer -Credential $Credential -SessionOption $sessionTimeOut -Authentication Credssp -ErrorAction Stop
            }
            catch [System.Management.Automation.Remoting.PSRemotingTransportException]
            {
                Write-Verbose "Auth type: Credssp failed. Trying a new pssession without Credssp."
                Write-Verbose "Establishing a new session to $($computer)."
                $sessionTimeOut = New-PSSessionOption -OpenTimeout 300000
                try
                {
                    New-PSSession -ComputerName $computer -Credential $Credential -SessionOption $sessionTimeOut -ErrorAction Stop
                }
                catch
                {
                    Write-Verbose "Failed to establish a new session to $($computer)."
                    $errorMessage = $_.Exception.Message

                    Write-Verbose "Something went wrong. Building new object to return to the pipeline."
                    New-TFPatchingObject -ComputerName $($computer) -Status $errorMessage -PatchingError
                    
                    Write-Error $errorMessage
                }
            }
            catch
            {
                Write-Verbose "Failed to establish a new session to $($computer)."
                $errorMessage = $_.Exception.Message

                Write-Verbose "Something went wrong. Building new object to return to the pipeline."
                New-TFPatchingObject -ComputerName $($computer) -Status $errorMessage -PatchingError
                
                Write-Error $errorMessage
            }
        }
    }
    end
    {
    }
}