function ConvertTo-TFHtml
{
     <#
    .Synopsis
       Convert HTML Fragments into an HTML page
    .DESCRIPTION
       Convert HTML Fragments into an HTML page
    .EXAMPLE
       
    .EXAMPLE
       
    #>
    [CmdletBinding()]
    param
    (
        # HTMLFragments
        [parameter(Mandatory)]
        [string[]]$HTMLFragment,

        # PreContent
        [parameter(Mandatory)]
        [string]$PreContent,

        # PostContent
        [parameter()]
        [string]$PostContent,

        # Title
        [parameter()]
        [string]$Title
    )
    begin
    {
        $cssStyleSheet = @"
body {
    background-color:white;
    font-family:Tahoma;
    font-size:10pt;
}
th {
    background-color:green;
    color:White;
}
table , th , td {
    border:1px solid green;
}
h4 {
    border:30px;
}
h4:hover {
    color:blue;
    cursor:pointer;
}
tr:hover {
    background-color:#00FF00;
}
"@
    }
    process
    {
        $stylesheet = "<style>$cssStyleSheet</style>" #| Out-String
        $jQueryURI = 'http://ajax.aspnetcdn.com/ajax/jQuery/jquery-1.8.2.min.js'
        $jQueryDataTableURI = 'http://ajax.aspnetcdn.com/ajax/jquery.dataTables/1.9.3/jquery.dataTables.min.js'
        #$stylesheet = "<link rel=`"stylesheet`" href=`"$cssStyleSheet`" type=`"text/css`" />"
        $titletag = "<title>$title</title>"
        $script = "<script charset=`"utf8`" type=`"text/javascript`" src=`"$jQueryURI`"></script>`n<script charset=`"utf8`" type=`"text/javascript`" src=`"$jQueryDataTableURI`"></script>"
        $datatable = ""
        $datatable = "<script type=`"text/javascript`">"
        $datatable += '$(document).ready(function () {'
        $datatable += "`$('.enhancedhtml-dynamic-table').dataTable();"
        $datatable += '} );'
        $datatable += "</script>"
        $body = $HTMLFragment | Out-String
        $body = "$PreContent`n$body"
        if ($PSBoundParameters.ContainsKey('PostContent')) {
            $body = "$body`n$PostContent"
        }
        $body = $body -replace '<tr><th>','<thead><tr><th>'
        $body = $body -replace '</th></tr>','</th></tr></thead>'
        ConvertTo-HTML -Head "$stylesheet`n$titletag`n$script`n$datatable" -Body $body
    }
    end
    {
    }
}
