
$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1")
$moduleName = Split-Path $moduleRoot -Leaf

Get-Module -Name $moduleName -All | Remove-Module -Force
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -Force

InModuleScope -ModuleName $moduleName {

    $testComputerName = "CRPCARITSVBRP03.think.local"

    Describe "Get-TFLogicMonLogin" {   

        Context "Testing Parameters" {

            $sut = Split-Path $MyInvocation.MyCommand.ScriptBlock.File -Leaf
            $cmdletName = $sut.Split('.')[0]
            $cmdlet = Get-Command -Name $cmdletName

            It "Should throw when mandatory parameters are not provided" {                
                $cmdlet.Parameters.ComputerName.Attributes.Mandatory | should be $true
            }        
        }

        Context "Testing function returns one object when ComputerName not think.dev" {
            
            $testLogicMonLogin = [PSCustomObject] @{
                Company   = 'thinkfinance'        
                AccessKey = 'Some LLE Access Key'
                AccessId  = 'Some LLE Access ID'
            }
            
            $testObject = Get-TFLogicMonLogin -ComputerName $testComputerName

            It "Should return a new object with correct properties" {                
                foreach ($property in $testObject.PSObject.Properties.Where( {$_.TypeNameOfValue -notlike 'System.Boolean'}))
                {
                    $testObject.$property | Should Be $testLogicMonLogin.$property
                }
            }                    
        }

        Context "Testing function returns two objects when ComputerName like think.dev" {

            $testLogicMonLogin = @(
                [PSCustomObject] @{
                    Company   = 'thinklle'        
                    AccessKey = 'Some LLE Access Key'
                    AccessId  = 'Some LLE Access ID'
                }
                [PSCustomObject] @{
                    Company  = 'thinkfinanc'
                    AccesKey = 'Some Prod Access Key'
                    AccessId = 'Some Prod Access Id'
                }
            )

            $testObject = Get-TFLogicMonLogin -ComputerName 'blah.think.dev'

            It "Should return two objects with correct properties" {                
                foreach ($property in $testObject.PSObject.Properties.Where( {$_.TypeNameOfValue -notlike 'System.Boolean'}))
                {
                    $testObject.$property | Should Be $testLogicMonLogin.$property
                }
            }
            It "Should return two objects to the pipeline" {
                $testObject.Count | Should be 2
            }
        } 
    }
}
