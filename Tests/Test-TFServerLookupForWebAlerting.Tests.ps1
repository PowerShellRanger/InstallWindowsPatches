
$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1")
$moduleName = Split-Path $moduleRoot -Leaf

Get-Module -Name $moduleName -All | Remove-Module -Force
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

InModuleScope -ModuleName $moduleName {
    
    Describe 'Test-TFServerLookupForWebAlerting' {   
                        
        Context 'Testing Parameters' {
                                    
            $sut = Split-Path $MyInvocation.MyCommand.ScriptBlock.File -Leaf
            $cmdletName = $sut.Split('.')[0]
            $cmdlet = Get-Command -Name $cmdletName

            It 'Should throw when mandatory parameters are not provided' {
                $cmdlet.Parameters.ComputerName.Attributes.Mandatory | should be $false
            }            
        }

        Context "Testing script execution" {
                                                                       
            It 'Should return correct ComputerNames when a match is found' {                                        
                Test-TFServerLookupForWebAlerting -ComputerName 'crp01mailflow01.paydayone.com' | Should be 'mailflow.thinkfinance.com'
                Test-TFServerLookupForWebAlerting -ComputerName 'crp02arch04.think.local' | Should be 'rass.thinkfinance.com'
                Test-TFServerLookupForWebAlerting -ComputerName 'crp02itschgr02.think.local' | Should be 'servicedesk.thinkfinance.com'
            }
            
            It 'Should return null when a match is not found' {                                        
                Test-TFServerLookupForWebAlerting -ComputerName 'foo' | Should be $null
            }
        }
    }
}
