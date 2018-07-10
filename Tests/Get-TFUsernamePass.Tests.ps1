
$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1")
$moduleName = Split-Path $moduleRoot -Leaf

Get-Module -Name $moduleName -All | Remove-Module -Force
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

InModuleScope -ModuleName $moduleName {
    
    Describe "Get-TFUsernamePass" {   
        
        $testComputerNames = @('foo.think.dev', 'foo.think.local', 'foo.cstfe.local', 'foo.paydayone.com')
        
        Context "Testing Parameters" {
                                    
            $sut = Split-Path $MyInvocation.MyCommand.ScriptBlock.File -Leaf
            $cmdletName = $sut.Split('.')[0]
            $cmdlet = Get-Command -Name $cmdletName

            It "Should throw when mandatory parameters are not provided" {
                $cmdlet.Parameters.ComputerName.Attributes.Mandatory | should be $true
            }
            It "Should accept an array of computer names" {
                Mock -CommandName Get-AutomationPSCredential -MockWith {return @{Username = 'foo'; Password = 'bar'}}
                $testUsernameAndPass = Get-TFUsernamePass -ComputerName $testComputerNames
                $testUsernameAndPass.Count | Should be 4                
            }
        }

        Context "Testing script execution" {
            
            foreach ($testComputer in $testComputerNames)
            {
                $domain = $testComputer.Split(".")[-2, -1] -join "."

                Mock -CommandName Get-AutomationPSCredential -MockWith {return $domain}                                
                
                It "Assert Get-AutomationPSCredential is called once for each computer name" {                    
                    $testUsernameAndPass = Get-TFUsernamePass -ComputerName $testComputer
                    $splat = @{
                        CommandName = 'Get-AutomationPSCredential'
                        Times       = 1
                        Exactly     = $true                        
                        Scope       = 'It'
                    }                    
                    Assert-MockCalled @splat
                }
                It "Should return credentials for the correct domain" {                    
                    $testUsernameAndPass = Get-TFUsernamePass -ComputerName $testComputer
                    $testUsernameAndPass | Should be $domain
                }
            }                                               
        }
    }
}
