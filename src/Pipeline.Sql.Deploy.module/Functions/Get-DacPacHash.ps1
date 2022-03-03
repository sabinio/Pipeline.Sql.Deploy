function Get-DacPacHash{
    [CmdletBinding()]
    [OutputType([String])]
    param (
        [string]$dacpacPath
    )

    [xml]$dacpacXml = New-Object xml
    $dacPacZipOriginStream=$null
    
    try{
        $FulldacPacPath = (Get-Item $dacpacPath).FullName
    
        $Zip = [io.compression.zipfile]::OpenRead($FulldacPacPath)
    }
    catch [System.IO.FileNotFoundException],[System.Management.Automation.ItemNotFoundException]{
      
        throw "Can't open dacpac file $dacpacPath doesn't exist"
    } catch {
        $Ex = New-Object System.Exception ("Error reading dacpac $dacpacPath probably not a valid dacpac",$_.Exception)
        throw $ex
    }  
    try{
        if (-not ($Zip.Entries.Name -eq "Origin.xml")){
            Throw "Can't find the Origin.xml file in the dacpac, would guess this isn't a dacpac"
        }
        $dacPacZipOriginStream = $Zip.GetEntry("Origin.xml").Open()
        $dacpacXml.Load($dacPacZipOriginStream)    
        $checksum = $dacpacXml.DacOrigin.Checksums.Checksum.'#text'
    }
    catch{Throw}
    finally{
        if ($null -ne $dacPacZipOriginStream){
            $dacPacZipOriginStream.Close()
            $dacPacZipOriginStream.Dispose()
        }
        if ($null -ne $Zip){ $Zip.Dispose()}
    }
    return $checksum
}