
$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1")
$moduleName = Split-Path $moduleRoot -Leaf

Get-Module -Name $moduleName -All | Remove-Module -Force
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

InModuleScope -ModuleName $moduleName {
    
    Describe 'Test-TFServerLookupFileShareWitness' {   
                        
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
                Test-TFServerLookupFileShareWitness -ComputerName 'crp02itsfsw01.think.local' | Should be 'crp02itsdbs01a.think.local' , 'crp02itsdbs01b.think.local'
                Test-TFServerLookupFileShareWitness -ComputerName 'crp02fsw01.think.local' | Should be 'crpcarthkdbs01a.think.local' , 'crpcarthkdbs01b.think.local'
            }
            
            It 'Should return null when a match is not found' {                                        
                Test-TFServerLookupFileShareWitness -ComputerName 'foo' | Should be $null
            }
        }
    }
}
