
function Get-ModelChecksum {
    [CmdletBinding()]
    [OutputType([String])]
    param (
        [xml]$modelxml
    )
    try {
        if (!$modelxml.DataSchemaModel.model){
            Throw "Can't find  model element correct location in the model.xml, not possible to return a checksum"
        }
        
        $checksum = ''

        $model = $modelxml.DataSchemaModel.Model.OuterXml;
        $checksum += (Get-FileHash -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($model)))).Hash;

    }
    catch { Throw }
    
    return $checksum
}
