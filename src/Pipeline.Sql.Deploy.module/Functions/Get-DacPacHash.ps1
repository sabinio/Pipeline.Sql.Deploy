function Get-DacPacHash{
    [CmdletBinding()]
    [OutputType([String])]
    param (
        [string]$dacpacPath
    )

    [xml]$dacpacXml = New-Object xml
    $dacPacZipOriginStream=$null
    

    try{
        $Zip = [io.compression.zipfile]::OpenRead($dacpacPath)
    }
    catch [System.IO.FileNotFoundException]{
      
        throw "Can't open dacpac file $dacpacPath doesn't exist"
    } catch {
        $Ex = New-Object System.Exception ("test",$_.Exception)
        throw "Error reading dacpac $dacpacPath probably not a valid dacpac"
    }  
    try{
        if ($Zip.Entries.Name -ne "Origin.xml"){
            Throw "Can't find the Origin.xml file in the dacpac, would guess this isn't a dacpac"
        }
        $dacPacZipOriginStream = $Zip.GetEntry("Origin.xml").Open()
        $dacpacXml.Load($dacPacZipOriginStream)    
        $checksum = $dacpacXml.DacOrigin.Checksums.Checksum.'#text'
    }
   
    finally{
        if ($null -ne $dacPacZipOriginStream){
            $dacPacZipOriginStream.Close()
            $dacPacZipOriginStream.Dispose()
        }
        if ($null -ne $Zip){ $Zip.Dispose()}
    }
    return $checksum
}