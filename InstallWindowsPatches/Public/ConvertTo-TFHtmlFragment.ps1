function ConvertTo-TFHtmlFragment
{
     <#
    .Synopsis
       Convert an input object to an HTML Fragment
    .DESCRIPTION
       Convert an input object to an HTML Fragment
    .EXAMPLE
       
    .EXAMPLE
       
    #>
    [CmdletBinding()]
    param
    (
        # InputObjects
        [parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [object[]]$InputObject,

        # PreContent
        [parameter(Mandatory)]
        [string]$PreContent,

        # PostContent
        [parameter()]
        [string]$PostContent
    )
    begin
    {
        $out = ''
        $css = ''
        $headerrow = ''
        [string]$tempid = [System.Guid]::NewGuid()
        $out += "<span class=`"sectionheader`" onclick=`"`$('#$tempid').toggle(500);`">$PreContent</span>`n"                    
        $temp = " id=`"$tempid`" style=`"display:none;`""
        $out += "<div $temp>"
        $css += "id=`"$tempid`""
        $out += "<table $css>"
        $properties = $InputObject[0] | Get-Member -MemberType Properties | select -ExpandProperty Name            
        foreach ($property in $properties) {
            $headerrow += "<th>$property</th>"
        }
        $out += "<tr>$headerrow</tr><tbody>"
    }
    process
    {        
        foreach ($object in $InputObject) {
            $datarow = ''            
            $properties = $object | Get-Member -MemberType Properties | select -ExpandProperty Name            
            foreach ($property in $properties) {
                $value = $object.($property)                    
                $datarow += "<td>$value</td>"                
            }            
            $out += "<tr>$datarow</tr>"
        }        
    }
    end
    {
        if ($PSBoundParameters.ContainsKey('PostContent')) {
            $out += "`n$PostContent"
        }
        $out += "</tbody></table></div>"
        $out
    }
}
