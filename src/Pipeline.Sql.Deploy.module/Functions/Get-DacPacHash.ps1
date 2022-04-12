function Get-DacPacHash {
    [CmdletBinding()]
    [OutputType([String])]
    param (
        [string]$dacpacPath,
        $rootPath
    )
    [xml]$dacpacXml = New-Object xml
    $dacPacZipModelStream = $null
    $IsRootDacPac = $null -eq $rootPath
    try {
        if ($null -eq $rootpath){
            $dacpacitem = (Get-Item $dacpacPath)
            $FulldacPacPath = $dacpacitem.FullName
            $rootpath = $dacpacitem.Directory
        }
        else{
            $FulldacPacPath = Join-Path $rootPath $dacpacPath
        }
        Write-Verbose "getting DacPac hash for $FulldacPacPath"
        $Zip = [io.compression.zipfile]::OpenRead($FulldacPacPath)
    }
    catch [System.IO.FileNotFoundException], [System.Management.Automation.ItemNotFoundException] {
        throw "Can't open dacpac file $dacpacPath doesn't exist"
    }
    catch {
        $Ex = New-Object System.Exception ("Error reading dacpac $dacpacPath probably not a valid dacpac", $_.Exception)
        throw $ex
    }
    try {
        if (-not ($Zip.Entries.Name -eq "model.xml")) {
            Throw "Can't find the model.xml file in the dacpac, would guess this isn't a dacpac"
        }
        $dacPacZipModelStream = $Zip.GetEntry("model.xml").Open()
        $dacpacXml.Load($dacPacZipModelStream)
        $checksum = ''
        $model = $dacpacXml.DataSchemaModel.Model.OuterXml;
        $checksum += (Get-FileHash -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($model)))).Hash;

        foreach ($dacpac in (Get-ReferencedDacpacsFromModel -modelxml $dacpacXml)) {
            $checksum += Get-DacPacHash -dacpacPath $dacpac -rootPath $rootPath
        }

        if ($IsRootDacPac) {
            $Zip.Entries | Where-Object { $_.Name -in ("predeploy.sql", "postdeploy.sql")} | ForEach-Object {
                $stream = $Zip.GetEntry($_.Name).open()
                $checksum += (Get-FileHash -InputStream $stream ).Hash;
                $stream.Close();
                $stream.Dispose();
                 
            }
        }
    }
    catch { Throw }
    finally {
        if ($null -ne $dacPacZipModelStream) {
            $dacPacZipModelStream.Close()
            $dacPacZipModelStream.Dispose()
        }
        if ($null -ne $Zip) { $Zip.Dispose() }
    }
    return $checksum
}
