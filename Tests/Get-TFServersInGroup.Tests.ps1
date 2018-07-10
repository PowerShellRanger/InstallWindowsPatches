
$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1")
$moduleName = Split-Path $moduleRoot -Leaf

Get-Module -Name $moduleName -All | Remove-Module -Force
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

InModuleScope -ModuleName $moduleName {

    Describe "Get-TFServersInGroup" {   
        
        $testDomains = @('foo.local', 'foo.dev', 'ci.foo.dev')
        $testGroupName = 'fooGroup'

        Context "Testing Parameters" {

            $sut = Split-Path $MyInvocation.MyCommand.ScriptBlock.File -Leaf
            $cmdletName = $sut.Split('.')[0]
            $cmdlet = Get-Command -Name $cmdletName

            It "Should throw when mandatory parameters are not provided" {
                $cmdlet.Parameters.Domain.Attributes.Mandatory | should be $true
                $cmdlet.Parameters.GroupName.Attributes.Mandatory | should be $true                
            }           
        }

        Context "Testing script execution" {                
            
            foreach ($testDomain in $testDomains)
            {
                if ($testDomain -eq 'ci.foo.dev')
                {                    
                    $members = 'CN=fooComputer,DC=ci,DC=foo,DC=dev'
                    Mock -CommandName Get-ADGroupMember -ModuleName $moduleName -MockWith {throw}
                }
                else
                {
                    $domainSuffix = $testDomain.Split('.')[-1]
                    $members = "CN=fooComputer,DC=foo,DC=$domainSuffix"
                    $mockADGroupMember = [PSCustomObject] @{
                        PSTypeName = 'Microsoft.ActiveDirectory.Management.ADPrincipal'
                        Name       = 'fooComputer'
                    }                                    
                    Mock -CommandName Get-ADGroupMember -ModuleName $moduleName  -MockWith {return $mockADGroupMember}                    
                }

                $mockADGroup = [PSCustomObject] @{
                    PSTypeName = 'Microsoft.ActiveDirectory.Management.ADGroup'
                    Name       = 'fooGroup'
                    Members    = $members
                }     
                $mockADComputer = [PSCustomObject] @{
                    PSTypeName  = 'Microsoft.ActiveDirectory.Management.ADComputer'
                    DNSHostName = "fooComputer.$testDomain"
                }    
                
                Mock -CommandName Get-ADGroup -ModuleName $moduleName  -MockWith {return $mockADGroup}                
                Mock -CommandName Get-ADComputer -ModuleName $moduleName  -MockWith {return $mockADComputer}

                $outputOfGettingServers = Get-TFServersInGroup -Domain $testDomain -GroupName $testGroupName
                
                It "Should return fooComputer.$testDomain to the pipeline" {
                    $outputOfGettingServers | Should Be $mockADComputer.DNSHostName
                }
            }           
            It "Assert mock Get-AdGroup was called exactly 3 times" {
                Assert-MockCalled -CommandName Get-ADGroup -Times 3 -Exactly -Scope Context
            }
            It "Assert mock Get-AdGroupMember was called exactly 3 times" {
                Assert-MockCalled -CommandName Get-ADGroupMember -Times 3 -Exactly -Scope Context
            }                        
        }
        <#
        Context "Testing bug that caused duplicate computer names" {
                         
            $testDomains = 'foo.local', 'notARealDomain.foo'
            
            $member = "CN=fooComputer,DC=foo,DC=local"

            $mockADGroup = [PSCustomObject] @{
                PSTypeName = 'Microsoft.ActiveDirectory.Management.ADGroup'
                Name       = $testGroupName
                Members    = $member
            }

            $mockADGroupMember = [PSCustomObject] @{
                PSTypeName = 'Microsoft.ActiveDirectory.Management.ADPrincipal'
                Name       = 'fooComputer'
            }

            $mockADComputer = [PSCustomObject] @{
                PSTypeName  = 'Microsoft.ActiveDirectory.Management.ADComputer'
                DNSHostName = "fooComputer.$testDomain"
            }

            Mock -CommandName Get-ADGroup -ModuleName $moduleName -MockWith {
                if ($domainName -eq 'foo.local') {return $mockADGroup}
                else {}
            }
            Mock -CommandName Get-ADGroupMember -ModuleName $moduleName  -MockWith {return $mockADGroupMember}
            Mock -CommandName Get-ADComputer -ModuleName $moduleName -MockWith {return $mockADComputer}            

            $outputOfGettingServers = Get-TFServersInGroup -Domain $testDomains -GroupName $testGroupName
            
            It "Should return 1 object to the pipeline" {
                @($outputOfGettingServers).Count | Should Be 1
            }        
            It "Assert mock Get-AdGroup was called exactly 2 times" {
                Assert-MockCalled -CommandName Get-ADGroup -Times 2 -Exactly -Scope Context
            }
            It "Assert mock Get-AdGroupMember was called exactly 1 times" {
                Assert-MockCalled -CommandName Get-ADGroupMember -Times 1 -Exactly -Scope Context
            }                        
        }
        #>
    }
}
