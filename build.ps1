
[cmdletbinding()]
param
(
    [parameter()]    
    [string]$Task = 'Default'
)

Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

foreach ($module in $modules) 
{
    if (-not (Get-Module -Name $module -ListAvailable)) 
    { 
        Install-Module -Name $module -Scope CurrentUser -Confirm:$false
        Import-module -Name $module
    }
}

Invoke-PSake -buildFile "$PSScriptRoot\psake.ps1" -taskList $Task -Verbose:$VerbosePreference
