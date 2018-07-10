
$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1")
$moduleName = Split-Path $moduleRoot -Leaf

Get-Module -Name $moduleName -All | Remove-Module -Force
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

InModuleScope -ModuleName $moduleName {

    Describe "Restart-TFComputerForPatching" {           
        
        #$password = ConvertTo-SecureString "Test" -AsPlainText -Force
        #$creds = New-Object System.Management.Automation.PSCredential ("Test",$password)
        
        Context "Testing Parameters" {
            
            $sut = Split-Path $MyInvocation.MyCommand.ScriptBlock.File -Leaf
            $cmdletName = $sut.Split('.')[0]
            $cmdlet = Get-Command -Name $cmdletName
            
            It "Should throw when mandatory parameters are not provided" {                
                $cmdlet.Parameters.ComputerName.Attributes.Mandatory | should be $true
            }        
        }              
    }
}
