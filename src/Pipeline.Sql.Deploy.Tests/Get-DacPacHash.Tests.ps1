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
    $ErrorActionPreference="stop"

    function generate-dacpac {
        param ($dacpac, $modelXML, $predeploycontent, $postdeploycontent)
        
        $Dacpaczip = "$dacpac.zip"

        $DacpacModel = "TestDrive:\DacPac\model.xml"
        new-item $DacpacModel -type file -force
        $modelXML | out-File $DacpacModel

        #Ascii encoding is used because on windows powershell UTF8 writes a BOM whereas on powershell core the BOM is not written
        if ($null -ne $predeploycontent) {
            $predeploy = "TestDrive:\DacPac\predeploy.sql"
            new-item $predeploy -type file -force
            $predeploycontent| out-File $predeploy  -Encoding Ascii -NoNewline
        }

        if ($null -ne $postdeploycontent) {
            $Postdeploy = "TestDrive:\DacPac\postdeploy.sql"
            new-item $Postdeploy -type file -force
            $postdeploycontent| out-File $Postdeploy  -Encoding Ascii -NoNewline
        }


    Get-ChildItem -Path "TestDrive:\DacPac\*.xml" , "TestDrive:\DacPac\*.sql" | Compress-Archive -DestinationPath $Dacpaczip
    move-item $Dacpaczip $Dacpac -Force #this is needed as powershell < 6 doesn't allow compress archive to anything other than a .zip
    }
    
    $baseModelXML =  @"
<DataSchemaModel xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">    
    <header>
%customdata1%
    </header>
%modelelement%
</DataSchemaModel>
"@ 

    $customdataRef = @"
<CustomData Category="Reference" Type="SqlSchema">
        <Metadata Name="FileName" Value="TestDrive:\DacPac\Referenced%name%.dacpac" />
        <Metadata Name="LogicalName" Value="Referenced%name%.dacpac" />
        %ExternalParts%
</CustomData> 
"@


    $modelelement = @"
    <model>
        <Element Type="SqlTable" Name="[dbo].[Account%num%]">
        </Element>
    </model>
"@
}

Describe 'Get-DacPacHash' {
    BeforeEach {
        Get-ChildItem $TestDrive | Remove-Item -Recurse;
    }
    It 'given a dacpac model element with hash of 1234 should return the hash (1234) from a dacpac' {

        $modelXML = $baseModelXML -replace "%customdata1", ""  -replace "%modelelement%", $modelelement
        $Dacpac = "TestDrive:\DacPac\TestDacPac.dacpac"
        generate-dacpac -dacpac $dacpac -modelXML $modelXML 

        Mock Get-ModelChecksum { "1234" } 
        Get-DacPacHash (Get-Item $Dacpac).FullName | Should -be "1234"
        Assert-MockCalled Get-ModelChecksum -Exactly 1  
    }

    It 'given a dacpac with hash of 1234 and a predeploy script the hash returned should be 1234 plus predeploy hash ' {
        
        $modelXML = $baseModelXML -replace "%customdata1", "" -replace "%modelelement%", $modelelement
        $Predeploy = @"
print "Pre deploy script"
"@ 
        $stream = [IO.MemoryStream]::new([Text.Encoding]::Ascii.GetBytes($Predeploy))
        $predeployhash = Get-FileHash -InputStream $stream # -Algorithm SHA256
        $stream.Dispose()

        $Dacpac = "TestDrive:\DacPac\TestDacPac.dacpac"
        generate-dacpac -dacpac $dacpac -modelXML $modelXML -predeploycontent $Predeploy

        Mock Get-ModelChecksum { "1234" } 
        $predeployhash.Hash | Should -be "BA9ECFD537D86552A3D9D8FFAAA2287C443B632668D58D7D01268D6430A07DF1"
        Get-DacPacHash (Get-Item $Dacpac).FullName | Should -be "1234$($predeployhash.hash)"
        Assert-MockCalled Get-ModelChecksum -Exactly 1  

    }
  

    It 'given a dacpac with hash of 1234 and a postdeploy script  the hash returned should be 1234 plus postdeploy hash ' {
        
        $modelXML = $baseModelXML -replace "%customdata1", ""  -replace "%modelelement%", $modelelement

        $Postdeploy = @"
print "Post deploy script"
"@ 
        $stream = [IO.MemoryStream]::new([Text.Encoding]::Ascii.GetBytes($Postdeploy))
        $postdeployhash = Get-FileHash -InputStream $stream -Algorithm SHA256
        $stream.Dispose()

        $Dacpac = "TestDrive:\DacPac\TestDacPac.dacpac"
        generate-dacpac -dacpac $dacpac -modelXML $modelXML -postdeploycontent $Postdeploy

        Mock Get-ModelChecksum { "1234" } 
        Get-DacPacHash (Get-Item $Dacpac).FullName | Should -be "1234$($postdeployhash.hash)"
        Assert-MockCalled Get-ModelChecksum -Exactly 1  

    }


    It 'given a dacpac with hash of 1234 and a predeploy script and a postdeploy script  then should be 1234 plus postdeploy hash plus predeploy hash' {

        $modelXML = $baseModelXML -replace "%customdata1", "" -replace "%modelelement%", $modelelement

        $Predeploy = @"
print "Pre deploy script"
"@ 
        $stream = [IO.MemoryStream]::new([Text.Encoding]::Ascii.GetBytes($Predeploy))
        $predeployhash = Get-FileHash -InputStream $stream -Algorithm SHA256
        $stream.Dispose()

        $Postdeploy = @"
print "Post deploy script"
"@ 
        $stream = [IO.MemoryStream]::new([Text.Encoding]::Ascii.GetBytes($Postdeploy))
        $postdeployhash = Get-FileHash -InputStream $stream -Algorithm SHA256
        $stream.Dispose()

        $Dacpac = "TestDrive:\DacPac\TestDacPac.dacpac"
        generate-dacpac -dacpac $dacpac -modelXML $modelXML -predeploycontent $Predeploy -postdeploycontent $Postdeploy

        Mock Get-ModelChecksum { "1234" } 
        Get-DacPacHash (Get-Item $Dacpac).FullName | Should -be "1234$($postdeployhash.hash)$($predeployhash.hash)"
        Assert-MockCalled Get-ModelChecksum -Exactly 1  
    }

    It 'given a changes to pre and post deploy ensure the hash is different' {


        $modelXML = $baseModelXML -replace "%customdata1", ""  -replace "%modelelement%", $modelelement
        $Dacpac = "TestDrive:\DacPac\TestDacPac.dacpac"
        generate-dacpac -dacpac $dacpac -modelXML $modelXML -predeploycontent "Some predeploy script"
        $hash1 = get-dacpachash (Get-Item $Dacpac).FullName
        
        generate-dacpac -dacpac $dacpac -modelXML $modelXML -predeploycontent "Some other script"
        $hash2 = get-dacpachash (Get-Item $Dacpac).FullName

        $hash1 | should -not -be $null
        $hash1 | should -not -be ""
        $hash1 | should -not -be $hash2
    }


    It 'given a dacpac with hash of 1234 which references a same db dacpac with a hash of 5678 should return the combined hash from both dacpacs' {

        $ref1 = $customdataRef -replace "%name%" , "dacpac"
        $modelelement1 = $modelelement -replace "%num%" , "1"
        $modelXML = $baseModelXML -replace "%customdata1", $ref1 -replace "%ExternalParts%", "" -replace "%modelelement%", $modelelement1
        $Dacpac = "TestDrive:\DacPac\TestDacPac.dacpac"
        generate-dacpac -dacpac $dacpac -modelXML $modelXML 

        $modelelement2 = $modelelement -replace "%num%" , "2"
        $modelXML = $baseModelXML -replace "%customdata1", "" -replace "%ExternalParts%", "" -replace "%modelelement%", $modelelement2
        $ReferencedDacpac = "TestDrive:\DacPac\Referenceddacpac.dacpac"
        generate-dacpac -dacpac $ReferencedDacpac -modelXML $modelXML 

        Mock Get-ModelChecksum { "1234" } -ParameterFilter {$modelxml.OuterXml.contains("Account1")}
        Mock Get-ModelChecksum { "5678" } -ParameterFilter {$modelxml.OuterXml.contains("Account2")}
        Get-DacPacHash (Get-Item $Dacpac).FullName | Should -be "12345678"
        Assert-MockCalled Get-ModelChecksum -Exactly 2  
    }


    It 'given a dacpac which references a dacpac which in turn references a third dacpac, combined hash should be obtains from all three dacpacs' {
        $ref1 = $customdataRef -replace "%name%" , "dacpac"
        $modelelement1 = $modelelement -replace "%num%" , "1"
        $modelXML = $baseModelXML -replace "%customdata1", $ref1 -replace "%ExternalParts%", "" -replace "%modelelement%", $modelelement1
        $Dacpac = "TestDrive:\DacPac\TestDacPac.dacpac"
        generate-dacpac -dacpac $dacpac -modelXML $modelXML 

        $ref2 = $customdataRef -replace "%name%" , "2dacpac"
        $modelelement2 = $modelelement -replace "%num%" , "2"
        $modelXML = $baseModelXML -replace "%customdata1", $ref2 -replace "%ExternalParts%", "" -replace "%modelelement%", $modelelement2
        $ReferencedDacpac = "TestDrive:\DacPac\Referenceddacpac.dacpac"
        generate-dacpac -dacpac $ReferencedDacpac -modelXML $modelXML 

        $modelelement3 = $modelelement -replace "%num%" , "3"
        $modelXML = $baseModelXML -replace "%customdata1", "" -replace "%modelelement%", $modelelement3
        $ReferencedDacpac = "TestDrive:\DacPac\Referenced2dacpac.dacpac"
        generate-dacpac -dacpac $ReferencedDacpac -modelXML $modelXML 

        Mock Get-ModelChecksum { "1234" } -ParameterFilter {$modelxml.OuterXml.contains("Account1")}
        Mock Get-ModelChecksum { "5678" } -ParameterFilter {$modelxml.OuterXml.contains("Account2")}
        Mock Get-ModelChecksum { "abcd" } -ParameterFilter {$modelxml.OuterXml.contains("Account3")}
        Get-DacPacHash (Get-Item $Dacpac).FullName | Should -be "12345678abcd"
        Assert-MockCalled Get-ModelChecksum -Exactly 3  
    }    

    It 'given a dacpac with hash of 1234 which references a different db dacpac with a hash of 5678 should return the hash (1234) from both dacpacs' {
        $ref1 = $customdataRef -replace "%name%" , "dacpac"
        $modelelement1 = $modelelement -replace "%num%" , "1"
        $modelXML = $baseModelXML -replace "%customdata1", $ref1 -replace "%ExternalParts%", '<Metadata Name="ExternalParts" Value="[(ReferencedDacpac)]" />' -replace "%modelelement%", $modelelement1
        $Dacpac = "TestDrive:\DacPac\TestDacPac.dacpac"
        generate-dacpac -dacpac $dacpac -modelXML $modelXML 

        $modelelement2 = $modelelement -replace "%num%" , "2"
        $modelXML = $baseModelXML -replace "%customdata1", "" -replace "%ExternalParts%", "" -replace "%modelelement%", $modelelement2
        $ReferencedDacpac = "TestDrive:\DacPac\Referenceddacpac.dacpac"
        generate-dacpac -dacpac $ReferencedDacpac -modelXML $modelXML 

        Mock Get-ModelChecksum { "1234" } -ParameterFilter {$modelxml.OuterXml.contains("Account1")}
        Mock Get-ModelChecksum { "5678" } -ParameterFilter {$modelxml.OuterXml.contains("Account2")}
        
        Get-DacPacHash (Get-Item $Dacpac).FullName | Should -be "1234"
        Assert-MockCalled Get-ModelChecksum -Exactly 1  
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

    It 'given an archive thats not got a model.xml return an error' {

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
        Compress-Archive $DacpacOrigin -DestinationPath $Dacpaczip -Force
        move-item $Dacpaczip $Dacpac -Force

        {Get-DacPacHash (Get-Item $Dacpac).FullName} | Should -Throw  "Can't find the model.xml file in the dacpac, would guess this isn't a dacpac"
    }    
}
