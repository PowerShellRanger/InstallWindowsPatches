
$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1")
$moduleName = Split-Path $moduleRoot -Leaf

Get-Module -Name $moduleName -All | Remove-Module -Force
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

InModuleScope -ModuleName $moduleName {    

    Describe "New-TFLogicMonHeader" {   

        Context "Testing Parameters" {

            $sut = Split-Path $MyInvocation.MyCommand.ScriptBlock.File -Leaf
            $cmdletName = $sut.Split('.')[0]
            $cmdlet = Get-Command -Name $cmdletName

            It "Should throw when mandatory parameters are not provided" {
                $cmdlet.Parameters.AccessKey.Attributes.Mandatory | should be $true
                $cmdlet.Parameters.AccessId.Attributes.Mandatory | should be $true
                $cmdlet.Parameters.Verb.Attributes.Mandatory | should be $true                             
            }        
        }

        Context "Testing function returns a header object" {
            
            $mockLogicMonHeader = @{
                Authorization  = 'LMv1 foo:Yjc0NGI4MDg5N2VjNTFhZDllZThkYTY3Y2M4YjNmYWZjZDk5ZDlmMzMxOWNhZTZjZWZkMzc4YTQ2NjYyYjFiYQ==:1493926038183'
                'Content-Type' = 'application/json'
            }
            
            $testObject = New-TFLogicMonHeader -AccessKey 'foo' -AccessId 'foo' -Verb Get

            It "Should return a new object with correct properties" {                
                foreach ($property in $testObject.PSObject.Properties)
                {
                    $testObject.$property | Should Be $mockLogicMonHeader.$property
                }
            }                    
        }
    }
}
