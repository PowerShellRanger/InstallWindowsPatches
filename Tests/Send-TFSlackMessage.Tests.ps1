
$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1")
$moduleName = Split-Path $moduleRoot -Leaf

Get-Module -Name $moduleName -All | Remove-Module -Force
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

InModuleScope -ModuleName $moduleName {

    Describe "Send-TFSlackMessage" {               
        
        Context "Testing Parameters" {
            $testInputObject = @{
                Name   = 'fooName'
                Status = 'fooStatus'
            }
            $clonedInputObject = $testInputObject.Clone()

            $sut = Split-Path $MyInvocation.MyCommand.ScriptBlock.File -Leaf
            $cmdletName = $sut.Split('.')[0]
            $cmdlet = Get-Command -Name $cmdletName

            It "Should throw when mandatory parameters are not provided" {
                $cmdlet.Parameters.InputObject.Attributes.Mandatory | should be $true
                $cmdlet.Parameters.Channel.Attributes.Mandatory | should be $true                                
            }
            <#It "Should accept an array of objects for the InputObject parameter" {
                {Send-TFSlackMessage -InputObject @($testInputObject,$clonedInputObject) -Channel 'foo' -Reason 'Summary'} | Should Not throw
            } #>       
        }              
    }
}
