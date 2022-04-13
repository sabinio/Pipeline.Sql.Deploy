function Get-ReferencedDacpacsFromModel {
    [CmdletBinding()]
    [OutputType([String[]])]
    param (
        [xml]$modelxml
    )
    $refdacpacs = @();

    foreach ($dacpac in (($modelxml.DataSchemaModel.Header.CustomData | `
    Where-Object { $_.Category -eq "Reference" `
    -and $_.Type -eq "SqlSchema" `
    -and -not ($_.MetaData.Name -eq "ExternalParts") } `
    ).MetaData | Where-Object { $_.Name -eq "LogicalName" })) {
        $refdacpacs += $dacpac.Value
    }
    return $refdacpacs
}