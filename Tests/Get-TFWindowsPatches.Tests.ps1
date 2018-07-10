
$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1")
$moduleName = Split-Path $moduleRoot -Leaf

Get-Module -Name $moduleName -All | Remove-Module -Force
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

InModuleScope -ModuleName $moduleName {

    Describe "Get-TFWindowsPatches" {   
        
        $testComputerName = "fooComputer.foo.com"        
        
        Context "Testing Parameters" {

            $sut = Split-Path $MyInvocation.MyCommand.ScriptBlock.File -Leaf
            $cmdletName = $sut.Split('.')[0]
            $cmdlet = Get-Command -Name $cmdletName

            It "Should throw when mandatory parameters are not provided" {                
                $cmdlet.Parameters.ComputerName.Attributes.Mandatory | should be $true
            }
        }    

        Context "Testing script execution when there is an error while checking patches" {
            
            Mock -CommandName New-Object -MockWith {throw 'foo status'}            
           
            $testGetPatchesFailed = Get-TFWindowsPatches -ComputerName $testComputerName -WarningAction SilentlyContinue
            
            It "Should return properties if there is an error while checking patches on $testComputerName" {
                $testGetPatchesFailed.ComputerName | Should Be $testComputerName
                $testGetPatchesFailed.Status | Should Be 'foo status'
                $testGetPatchesFailed.Error | Should Be $true
            }                        
        }
        
        Context "Testing script execution when there is an error while checking patches" {
            
            class MicrosoftUpdateSearcher 
            {
                [bool] $isCalledSearch = $false
                [PSCustomObject] $SearchObject

                [PSCustomObject]Search([string] $criteria)
                {
                    $this.isCalledSearch = $true

                    $this.SearchObject = [PSCUstomObject] @{
                        Updates = 
                        @(
                            [PSCustomObject] @{
                                KBArticleIDs             = '00000'
                                RebootRequired           = $false
                                LastDeploymentChangeTime = Get-Date
                                Title                    = 'Some title for an Update'
                            },
                            [PSCustomObject] @{
                                KBArticleIDs             = '00001'
                                RebootRequired           = $false
                                LastDeploymentChangeTime = Get-Date
                                Title                    = 'Some title for an Update'
                            }
                        )
                    }
                    
                    return $this.SearchObject
                }
            }

            $updateSearcher = [MicrosoftUpdateSearcher]::new()
            $mockedUpdateData = $updateSearcher.Search('Criteria').Updates
            
            Mock -CommandName New-Object -MockWith {return $updateSearcher}
            Mock -CommandName Get-EventLog -MockWith {return 'No'}            
           
            $testGetPatches = Get-TFWindowsPatches -ComputerName $testComputerName
            
            It "Should return correct properties after checking for patches on $testComputerName" {
                $testGetPatches.ComputerName | Should Be $testComputerName
                $testGetPatches.Updates | Should be $mockedUpdateData.Count
                $testGetPatches.Error | Should be $false
                #$testGetPatches.IndividualUpdates | Should be $mockedUpdateData
            }                        
        }
    }
}
