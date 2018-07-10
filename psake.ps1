
Import-module -name 'Pester' , 'psake' , 'PSScriptAnalyzer'

function Invoke-TestFailure
{
    param
    (
        [Parameter(Mandatory)]
        [ValidateSet('Unit', 'Integration', 'Acceptance')]
        [string]$TestType,

        [Parameter(Mandatory)]
        $PesterResults
    )

    if ($TestType -eq 'Unit') 
    {
        $errorID = 'UnitTestFailure'
    }
    elseif ($TestType -eq 'Integration')
    {
        $errorID = 'InetegrationTestFailure'
    }
    else
    {
        $errorID = 'AcceptanceTestFailure'
    }

    $errorCategory = [System.Management.Automation.ErrorCategory]::LimitsExceeded
    $errorMessage = "$TestType Test Failed: $($PesterResults.FailedCount) tests failed out of $($PesterResults.TotalCount) total test."
    $exception = New-Object -TypeName System.SystemException -ArgumentList $errorMessage
    $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, $errorID, $errorCategory, $null

    Write-Output "##vso[task.logissue type=error]$errorMessage"
    throw $errorRecord
}

FormatTaskName "--------------- {0} ---------------"

Properties {
    # psake makes variables declared here available in other scriptblocks
    $mainControlScript = 'Install_Windows_Patches_Main.ps1'
    $testsPath = "$PSScriptRoot\Tests"
    $testResultsPath = "$TestsPath\Results"        
}

Task Default -Depends UnitTests, Build, Clean

Task Init {     
    "Build System Details:"
    $env:BUILD_REPOSITORY_NAME
    "`n"
}

Task ScriptAnalysis -Depends Init {
    "Starting script analysis..."
    Invoke-ScriptAnalyzer -Path $mainControlScript
}

Task UnitTests -Depends ScriptAnalysis {
    "Starting unit tests..."
    
    # Make sure Test Result location exists
    New-Item $testResultsPath -ItemType Directory -Force

    $pesterResults = Invoke-Pester -Path "$testsPath" -OutputFile "$testResultsPath\UnitTest.xml" -OutputFormat NUnitXml -PassThru
    
    if ($pesterResults.FailedCount)
    {
        Invoke-TestFailure -TestType Unit -PesterResults $pesterResults
    }
}

Task Build -Depends UnitTests {
    "Starting update of module manifest..."
    
    # Get public functions to export
    $functions = Get-ChildItem "$PSScriptRoot\$env:BUILD_REPOSITORY_NAME\Public\*.ps1" | Where-Object { $_.name -notmatch 'Tests'} | Select-Object -ExpandProperty basename    

    # Bump the module version
    $manifest = Import-PowerShellDataFile -Path "$PSScriptRoot\$env:BUILD_REPOSITORY_NAME\*.psd1"
    [version]$version = $manifest.ModuleVersion
    
    # Add one to the build of the version number
    [version]$newVersion = "{0}.{1}.{2}" -f $version.Major, $version.Minor, ($version.Build + 1)
    
    # Update the manifest file
    Update-ModuleManifest -Path "$PSScriptRoot\$env:BUILD_REPOSITORY_NAME\*.psd1" -ModuleVersion $newVersion -FunctionsToExport $functions        
}

Task Clean {
    "Starting cleaning enviroment..."        
    
    # Remove Test Results from previous runs    
    Remove-Item "$TestResultsPath\*.xml"
}