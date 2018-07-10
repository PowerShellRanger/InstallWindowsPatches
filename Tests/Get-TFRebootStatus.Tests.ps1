
$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1")
$moduleName = Split-Path $moduleRoot -Leaf

Get-Module -Name $moduleName -All | Remove-Module -Force
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

InModuleScope -ModuleName $moduleName {

    Describe "Get-TFRebootStatus" {   
        
        $testComputerName = "CRPCARITSVBRP03.think.local"
        $session = [PSCustomObject] @{
            Id           = 1
            Name         = 'Session1'
            ComputerName = $testComputerName
            State        = 'Open'
        }
        
        Context "Testing Parameters" {

            $sut = Split-Path $MyInvocation.MyCommand.ScriptBlock.File -Leaf
            $cmdletName = $sut.Split('.')[0]
            $cmdlet = Get-Command -Name $cmdletName

            It "Should throw when mandatory parameters are not provided" {
                $cmdlet.Parameters.ComputerName.Attributes.Mandatory | should be $true
                $cmdlet.Parameters.Session.Attributes.Mandatory | should be $true
            }        
        }

        Context "Testing result of NO pending reboot" {            

            Mock -CommandName Invoke-Command -MockWith {return @{ComputerName = $testComputerName; RebootRequired = $false}}
           
            $mockSession = New-PSSession -ComputerName localhost -ErrorAction Stop
            $testRebootRequiredProperty = Get-TFRebootStatus -ComputerName $testComputerName -Session $mockSession

            It "Should return false for the RebootRequired property when $testComputerName does not have a pending reboot" {
                $testRebootRequiredProperty.RebootRequired | Should Be $false
            }
            It "Should return a ComputerName property equal to $testComputerName" {
                $testRebootRequiredProperty.ComputerName | Should Be $testComputerName
            }            
            It "Should try Invoke-Command one time when a session IS established" {
                Assert-MockCalled -CommandName Invoke-Command -Times 1 -Exactly -Scope Context
            }
        }
        
        Context "Testing result of a pending reboot" {
            
            Mock -CommandName Invoke-Command -MockWith {return @{ComputerName = $testComputerName; RebootRequired = $true}}

            $mockSession = New-PSSession -ComputerName localhost -ErrorAction Stop
            $testRebootRequiredProperty = Get-TFRebootStatus -ComputerName $testComputerName -Session $mockSession

            It "Should return true for the RebootRequired property when $testComputerName has a pending reboot" {
                $testRebootRequiredProperty.RebootRequired | Should Be $true
            }
            It "Should return a ComputerName property equal to $testComputerName" {
                $testRebootRequiredProperty.ComputerName | Should Be $testComputerName
            }            
            It "Should try Invoke-Command one time when a session IS established" {
                Assert-MockCalled -CommandName Invoke-Command -Times 1 -Exactly -Scope Context
            }
        }
    }
}
