function Get-DacPacHash {
    [CmdletBinding()]
    [OutputType([String])]
    param (
        [string]$dacpacPath,
        $rootPath
    )
    [xml]$dacpacXml = New-Object xml
    $dacPacZipOriginStream = $null
    $dacPacZipModelStream = $null
    try {
        if ($null -eq $rootpath){
            $dacpacitem = (Get-Item $dacpacPath)
            $FulldacPacPath = $dacpacitem.FullName
            $rootpath = $dacpacitem.Directory
        }
        else{
            $FulldacPacPath = Join-Path $rootPath $dacpacPath
        }
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
        if (-not ($Zip.Entries.Name -eq "Origin.xml")) {
            Throw "Can't find the Origin.xml file in the dacpac, would guess this isn't a dacpac"
        }
        if (-not ($Zip.Entries.Name -eq "model.xml")) {
            Throw "Can't find the model.xml file in the dacpac, would guess this isn't a dacpac"
        }
        $dacPacZipModelStream = $Zip.GetEntry("model.xml").Open()
        $dacpacXml.Load($dacPacZipModelStream)
        $checksum = ''
        foreach ($dacpac in (($dacpacXml.DataSchemaModel.Header.CustomData | `
                        Where-Object { $_.Category -eq "Reference" `
                            -and $_.Type -eq "SqlSchema" `
                            -and -not ($_.MetaData.Name -eq "ExternalParts") } `
                ).MetaData | Where-Object { $_.Name -eq "LogicalName" })) {
            $checksum += Get-DacPacHash -dacpacPath $dacpac.Value -rootPath $rootPath
        }
        $dacPacZipOriginStream = $Zip.GetEntry("Origin.xml").Open()
        $dacpacXml.Load($dacPacZipOriginStream)
        #Write-Host "$dacpacPath - has checksum - $($dacpacXml.DacOrigin.Checksums.Checksum.'#text') "
        $checksum += $dacpacXml.DacOrigin.Checksums.Checksum.'#text'
    }
    catch { Throw }
    finally {
        if ($null -ne $dacPacZipOriginStream) {
            $dacPacZipOriginStream.Close()
            $dacPacZipOriginStream.Dispose()
        }
        if ($null -ne $dacPacZipModelStream) {
            $dacPacZipModelStream.Close()
            $dacPacZipModelStream.Dispose()
        }
        if ($null -ne $Zip) { $Zip.Dispose() }
    }
    return $checksum
}