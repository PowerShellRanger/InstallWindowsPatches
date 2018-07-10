
$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1")
$moduleName = Split-Path $moduleRoot -Leaf

Get-Module -Name $moduleName -All | Remove-Module -Force
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -Force

$testSplat = @{
    ComputerName = 'TESTCOMPUTER'
    Updates      = 5
    Date         = (Get-Date -format MM\\dd\\yy)
    Duration     = '0:2:44'
    Status       = 'Test Status'
}

$fakeObject = [PSCustomObject] @{
    ComputerName = $testSplat.ComputerName
    Updates      = $testSplat.Updates
    Date         = $testSplat.Date
    Duration     = $testSplat.Duration
    Status       = $testSplat.Status
}
 
Describe "New-TFPatchingObject" {

    Context "Testing Parameters" {
        
        $sut = Split-Path $MyInvocation.MyCommand.ScriptBlock.File -Leaf
        $cmdletName = $sut.Split('.')[0]
        $cmdlet = Get-Command -Name $cmdletName

        It "Should throw when mandatory parameters are not provided" {                
            $cmdlet.Parameters.ComputerName.Attributes.Mandatory | should be $true
        }                  
    }

    Context "Testing new object is returned to the pipeline" {
        
        It "Should return a new object with correct properties" {
            $testObject = New-TFPatchingObject @testSplat
            foreach ($property in $testObject.PSObject.Properties.Where( {$_.TypeNameOfValue -notlike 'System.Boolean'}))
            {
                $testObject.$property | Should Be $testSplat.$property
            }
        }
        It "Should accept pipeline input" {
            $testObject = $fakeObject | New-TFPatchingObject
            foreach ($property in $testObject.PSObject.Properties.Where( {$_.TypeNameOfValue -notlike 'System.Boolean'}))
            {
                $testObject.$property | Should Be $fakeObject.$property
            }
        }
    }
}
