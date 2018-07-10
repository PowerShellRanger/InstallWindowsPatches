
$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1")
$moduleName = Split-Path $moduleRoot -Leaf

Get-Module -Name $moduleName -All | Remove-Module -Force
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

InModuleScope -ModuleName $moduleName {

    $testComputerName = "CRPCARITSVBRP03.think.local"

    $mockLogicMonData = @"
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
  <Obj RefId="0">
    <TN RefId="0">
      <T>System.Management.Automation.PSCustomObject</T>
      <T>System.Object</T>
    </TN>
    <MS>
      <I32 N="status">200</I32>
      <S N="errmsg">OK</S>
      <Obj N="data" RefId="1">
        <TNRef RefId="0" />
        <MS>
          <I32 N="total">1</I32>
          <Obj N="items" RefId="2">
            <TN RefId="1">
              <T>System.Object[]</T>
              <T>System.Array</T>
              <T>System.Object</T>
            </TN>
            <LST>
              <Obj RefId="3">
                <TNRef RefId="0" />
                <MS>
                  <I32 N="id">1485</I32>
                  <S N="name">CRPCARITSVBRP03.think.local</S>
                  <S N="displayName">CRPCARITSVBRP03.think.local</S>
                  <I32 N="deviceType">0</I32>
                  <I32 N="relatedDeviceId">-1</I32>
                  <I32 N="currentCollectorId">16</I32>
                  <I32 N="preferredCollectorId">16</I32>
                  <I32 N="preferredCollectorGroupId">3</I32>
                  <S N="preferredCollectorGroupName">Think.local Collectors</S>
                  <S N="description"></S>
                  <I32 N="createdOn">1475167801</I32>
                  <I32 N="updatedOn">1491412652</I32>
                  <B N="disableAlerting">false</B>
                  <B N="canUseRemoteSession">false</B>
                  <I32 N="autoPropsAssignedOn">1491371421</I32>
                  <I32 N="autoPropsUpdatedOn">1491371422</I32>
                  <I32 N="scanConfigId">0</I32>
                  <S N="link"></S>
                  <B N="enableNetflow">false</B>
                  <I32 N="netflowCollectorId">0</I32>
                  <I32 N="netflowCollectorGroupId">0</I32>
                  <Nil N="netflowCollectorGroupName" />
                  <I32 N="lastDataTime">0</I32>
                  <I32 N="lastRawdataTime">0</I32>
                  <S N="hostGroupIds">252</S>
                  <S N="sdtStatus">none-none-none</S>
                  <S N="userPermission">write</S>
                  <S N="hostStatus">normal</S>
                  <S N="alertStatus">none</S>
                  <I32 N="alertStatusPriority">100000</I32>
                  <I32 N="awsState">1</I32>
                  <I32 N="azureState">1</I32>
                  <S N="alertDisableStatus">none-none-none</S>
                  <Nil N="alertingDisabledOn" />
                  <S N="collectorDescription">THINK\CRPCARITSLMC01</S>
                  <Nil N="netflowCollectorDescription" />
                  <Obj N="customProperties" RefId="4">
                    <TNRef RefId="1" />
                    <LST />
                  </Obj>
                  <I32 N="upTimeInSeconds">473832</I32>
                  <I32 N="deletedTimeInMs">0</I32>
                  <I32 N="toDeleteTimeInMs">0</I32>
                  <B N="hasDisabledSubResource">false</B>
                  <Obj N="manualDiscoveryFlags" RefId="5">
                    <TNRef RefId="0" />
                    <MS>
                      <B N="winprocess">true</B>
                      <B N="linuxprocess">false</B>
                      <B N="winservice">true</B>
                    </MS>
                  </Obj>
                  <B N="ancestorHasDisabledLogicModule">false</B>
                </MS>
              </Obj>
            </LST>
          </Obj>
          <Nil N="searchId" />
        </MS>
      </Obj>
    </MS>
  </Obj>
</Objs>
"@
 
    $testLogicMonData = [System.Management.Automation.PSSerializer]::DeserializeAsList($mockLogicMonData)

    $mockLogicMonLogin = [PSCustomObject] @{
        Company   = 'thinkfinance'        
        AccessKey = 'Some Prod Access Key'
        AccessId  = 'Some Prod Access ID'
    }
    $mockLogicMonHeader = @{
        Authorization  = 'LMv1 Zg6hf2Q9rfx2CPI9Mi5t:NTVhMGU4NjM3NjY2MTBjMmYyMTFmYTRkYmIwZDdmZDM5OGE5ZmFkZDBiNzE3YTRiMTAyMDAzOGNlYjVkNWE5MA==:1493911862237'
        'Content-Type' = 'application/json'
    }

    Describe "Get-TFLogicMonDevice" {   

        Context "Testing Parameters" {

            $sut = Split-Path $MyInvocation.MyCommand.ScriptBlock.File -Leaf
            $cmdletName = $sut.Split('.')[0]
            $cmdlet = Get-Command -Name $cmdletName

            It "Should throw when mandatory parameters are not provided" {                
                $cmdlet.Parameters.ComputerName.Attributes.Mandatory | should be $true       
            }         
        }

        Context "Testing function returns data from ProdLogicMon" {

            Mock -CommandName Get-TFLogicMonLogin -MockWith {return $mockLogicMonLogin}
            Mock -CommandName New-TFLogicMonHeader -MockWith {return $mockLogicMonHeader} 
            Mock -CommandName Invoke-RestMethod -MockWith {return $testLogicMonData} 
            
            $testObject = Get-TFLogicMonDevice -ComputerName $testComputerName

            It "Assert each mock called 1 time" {
                Assert-MockCalled -CommandName Get-TFLogicMonLogin -Times 1
                Assert-MockCalled -CommandName New-TFLogicMonHeader -Times 1            
                Assert-MockCalled -CommandName Invoke-RestMethod -Times 1
            }        
            It "Should return an object with a name parameter" {
                $testObject.name | Should Be $testLogicMonData.data.items.name
            }
            It "Should return one object to the pipeline" {
                @($testObject).Count | Should Be 1
            }       
        }        
    }
}
