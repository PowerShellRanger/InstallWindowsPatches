function Test-TFServerLookupFileShareWitness
{
    <#
    .Synopsis
       Test to see if a server matches the list of FileShare Witnesses we know about.
    .DESCRIPTION
       Use this function to test to see if a server matches the list of FileShare Witnesses we know about.
    .EXAMPLE
       
    .EXAMPLE
       
    #>
    [CmdletBinding()]
    param
    (
        # ComputerName
        [Parameter(            
            ValueFromPipeline, 
            ValueFromPipelineByPropertyName
        )]
        [string[]]$ComputerName = $env:COMPUTERNAME
    )
    begin
    {
    }
    process
    {                        
        $lookupTable = @{
            'crp02itsfsw01.think.local' = 'crp02itsdbs01a.think.local' , 'crp02itsdbs01b.think.local'
            'crp02fsw01.think.local'    = 'crpcarthkdbs01a.think.local' , 'crpcarthkdbs01b.think.local'
        }

        $ComputerName | ForEach-Object { $lookupTable[$_] }
    }
    end
    {
    }
}