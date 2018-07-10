function Get-TFServersInGroup
{
    <#
    .Synopsis
       Get objects in an AD group
    .DESCRIPTION
       Use this function to get objects from an AD group. This function works on groups with members from trusted Domain.
    .EXAMPLE
       
    .EXAMPLE
       
    #>
    [CmdletBinding()]
    param
    (
        # Domain
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$Domain,

        # GroupName
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$GroupName
    )
    begin
    {
    }
    process
    {        
        foreach ($domainName in $Domain) 
        {
            $adGroup = ''
            Write-Verbose "Getting AD Group: $($groupName) from Domain: $($domainName)."
            $adGroup = Get-ADGroup -Filter {Name -like $groupName} -Server $domainName -Properties Members

            if (-not $adGroup.Members)
            {
                Write-Warning "No members were found in group: $($groupName)."
                continue
            }
            try 
            {
                Write-Verbose "Getting AD GroupMembers from Group: $($adGroup.Name)"
                $adGroupMembers = Get-ADGroupMember -Identity $adGroup.Name -Server $domainName -ErrorAction Stop
                Write-Verbose "Getting AD Computers from Group: $($adGroup.Name)"
                ($adGroupMembers | ForEach-Object {Get-ADComputer -Identity $_.Name -Server $domainName -ErrorAction Stop}).DNSHostName.ToLower()
            }
            catch 
            {
                Write-Verbose "$($domainName) is a subdomain, trying to get members a different way."
                $adGroupMembers = $adGroup.Members
                foreach ($adGroupMember in $adGroupMembers)
                {
                    $server = $adGroupMember.Split(',')[0].Split('=')[1]
                    $domainName = ($adGroupMember -split ",DC=" | select -Last 3) -join "."
                    if ($domainName -like "CN=*,*.*") 
                    {
                        $domainName = $domainName.Split('.')[-2..-1] -join '.'
                    }    
                    "$($server.ToLower()).$($domainName.ToLower())"
                }
            }
        }        
    }
    end
    {
    }
}