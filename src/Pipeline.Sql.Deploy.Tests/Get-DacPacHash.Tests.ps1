BeforeAll {
	Set-StrictMode -Version 1.0
    if (-not (Test-path  Variable:\ProjectName)) { $ProjectName = (get-item $PSScriptRoot).basename -replace ".tests", "" }
    $CommandName = [IO.Path]::GetFileName($PSCommandPath).Replace(".Tests.ps1", "")
    
    if (-not (Test-path  Variable:\ModulePath) -or "$ModulePath" -eq "") {$ModulePath = "$PSScriptRoot\..\$ProjectName.module" }

    get-module $ProjectName | Remove-Module -Force
    Get-ChildItem ([System.IO.Path]::Combine($ModulePath,"Functions","*.ps1")) -Recurse | ForEach-Object{
         Write-Verbose "loading $_" -Verbose;
       . $_.FullName
    }
}

Describe 'Get-DacPacHash' {
    It 'given a dacpac with hash of 1234 should return the hash (1234) from a dacpac' {

        $Dacpac = "TestDrive:\DacPac\TestDacPac.dacpac"
        $Dacpaczip = "$dacpac.zip"
        $DacpacOrigin = "TestDrive:\DacPac\Origin.xml"
        new-item $DacpacOrigin -type file -force
        @"
<DacOrigin xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">
    <Checksums>
        <Checksum Uri="/model.xml">1234</Checksum>
    </Checksums>
</DacOrigin>
"@ | out-File $DacpacOrigin
        Compress-Archive $DacpacOrigin -DestinationPath $Dacpaczip
        move-item $Dacpaczip $Dacpac -Force #this is needed as powershell < 6 doesn't allow compress archive to anything other than a .zip
    
        Get-DacPacHash (Get-Item $Dacpac).FullName | Should -be "1234"
    }
    It 'given a file thats not an archive return an error' {

        $DacpacOrigin = "TestDrive:\DacPac\Origin.xml"
        new-item $DacpacOrigin -type file -force
        @"
<DacOrigin xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">
    <Checksums>
        <Checksum Uri="/model.xml">1234</Checksum>
    </Checksums>
</DacOrigin>
"@ | out-File $DacpacOrigin
    
        {Get-DacPacHash (Get-Item $DacpacOrigin).FullName} | Should -Throw "Error reading dacpac * probably not a valid dacpac"
    }

    It 'given a file that doesnt exist return an error' {
    
        {Get-DacPacHash c:\somenonexistentFile} | Should -Throw "Can't open dacpac file * doesn't exist"
    }

    It 'given an archives thats not got an origin.xml return an error' {

        $Dacpac = "TestDrive:\DacPac\TestDacPac.dacpac"
        $Dacpaczip = "$dacpac.zip"
        $DacpacOther= "TestDrive:\DacPac\Other.xml"
        new-item $DacpacOther -type file -force
        @"
<DacOrigin xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">
    <Checksums>
        <Checksum Uri="/model.xml">1234</Checksum>
    </Checksums>
</DacOrigin>
"@ | out-File $DacpacOther
        Compress-Archive $DacpacOther -DestinationPath $Dacpaczip -Force
        move-item $Dacpaczip $Dacpac -Force

        {Get-DacPacHash (Get-Item $Dacpac).FullName} | Should -Throw  "Can't find the Origin.xml file in the dacpac, would guess this isn't a dacpac"
    }
   
}
