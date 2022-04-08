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

        $DacpacModel = "TestDrive:\DacPac\model.xml"
        new-item $DacpacModel -type file -force
        @"
<DataSchemaModel xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">     
</DataSchemaModel>
"@ | out-File $DacpacModel
        Get-ChildItem -Path $DacpacOrigin, $DacpacModel | Compress-Archive -DestinationPath $Dacpaczip
        move-item $Dacpaczip $Dacpac -Force #this is needed as powershell < 6 doesn't allow compress archive to anything other than a .zip
    
        Get-DacPacHash (Get-Item $Dacpac).FullName | Should -be "1234"
    }
  
    It 'given a dacpac with hash of 5678 which references a same db dacpac with a hash of 1234 should return the hash (12345678) from both dacpacs' {

        $Dacpac = "TestDrive:\DacPac\TestDacPac.dacpac"
        $Dacpaczip = "$dacpac.zip"
        $DacpacOrigin = "TestDrive:\DacPac\Origin.xml"
        new-item $DacpacOrigin -type file -force
        @"
<DacOrigin xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">
    <Checksums>
        <Checksum Uri="/model.xml">5678</Checksum>
    </Checksums>
</DacOrigin>
"@ | out-File $DacpacOrigin

        $DacpacModel = "TestDrive:\DacPac\model.xml"
        new-item $DacpacModel -type file -force
        @"
<DataSchemaModel xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">     
    <Header>
        <CustomData Category="Reference" Type="SqlSchema">
            <Metadata Name="FileName" Value="TestDrive:\DacPac\ReferencedDacPac.dacpac" />
            <Metadata Name="LogicalName" Value="ReferencedDacPac.dacpac" />
        </CustomData>     
    </Header>
</DataSchemaModel>
"@ | out-File $DacpacModel

        Get-ChildItem -Path $DacpacOrigin, $DacpacModel | Compress-Archive -DestinationPath $Dacpaczip
        move-item $Dacpaczip $Dacpac -Force #this is needed as powershell < 6 doesn't allow compress archive to anything other than a .zip



        $DacpacReferenced = "TestDrive:\DacPac\ReferencedDacPac.dacpac"
        $DacpacReferencedzip = "$DacpacReferenced.zip"
        $DacpacReferencedOrigin = "TestDrive:\ReferencedDacPac\Origin.xml"
        new-item $DacpacReferencedOrigin -type file -force
        @"
<DacOrigin xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">
    <Checksums>
        <Checksum Uri="/model.xml">1234</Checksum>
    </Checksums>
</DacOrigin>
"@ | out-File $DacpacReferencedOrigin

        $DacpacReferencedModel = "TestDrive:\ReferencedDacPac\model.xml"
        new-item $DacpacReferencedModel -type file -force
        @"
<DataSchemaModel xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">     
</DataSchemaModel>
"@ | out-File $DacpacReferencedModel

        Get-ChildItem -Path $DacpacReferencedOrigin, $DacpacReferencedModel | Compress-Archive -DestinationPath $DacpacReferencedzip
        move-item $DacpacReferencedzip $DacpacReferenced -Force #this is needed as powershell < 6 doesn't allow compress archive to anything other than a .zip
    
        Get-DacPacHash (Get-Item $Dacpac).FullName | Should -be "12345678"
    }    

    It 'given a dacpac which references a dacpac which in turn references a third dacpac, hash should be obtains from all three dacpacs' {

        $Dacpac = "TestDrive:\DacPac\TestDacPac.dacpac"
        $Dacpaczip = "$dacpac.zip"
        $DacpacOrigin = "TestDrive:\DacPac\Origin.xml"
        new-item $DacpacOrigin -type file -force
        @"
<DacOrigin xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">
    <Checksums>
        <Checksum Uri="/model.xml">5678</Checksum>
    </Checksums>
</DacOrigin>
"@ | out-File $DacpacOrigin

        $DacpacModel = "TestDrive:\DacPac\model.xml"
        new-item $DacpacModel -type file -force
        @"
<DataSchemaModel xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">     
    <Header>
        <CustomData Category="Reference" Type="SqlSchema">
            <Metadata Name="FileName" Value="TestDrive:\DacPac\ReferencedDacPac.dacpac" />
            <Metadata Name="LogicalName" Value="ReferencedDacPac.dacpac" />
        </CustomData>     
    </Header>
</DataSchemaModel>
"@ | out-File $DacpacModel

        Get-ChildItem -Path $DacpacOrigin, $DacpacModel | Compress-Archive -DestinationPath $Dacpaczip
        move-item $Dacpaczip $Dacpac -Force #this is needed as powershell < 6 doesn't allow compress archive to anything other than a .zip



        $DacpacReferenced = "TestDrive:\DacPac\ReferencedDacPac.dacpac"
        $DacpacReferencedzip = "$DacpacReferenced.zip"
        $DacpacReferencedOrigin = "TestDrive:\ReferencedDacPac\Origin.xml"
        new-item $DacpacReferencedOrigin -type file -force
        @"
<DacOrigin xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">
    <Checksums>
        <Checksum Uri="/model.xml">1234</Checksum>
    </Checksums>
</DacOrigin>
"@ | out-File $DacpacReferencedOrigin

        $DacpacReferencedModel = "TestDrive:\ReferencedDacPac\model.xml"
        new-item $DacpacReferencedModel -type file -force
        @"
        <DataSchemaModel xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">     
        <Header>
            <CustomData Category="Reference" Type="SqlSchema">
                <Metadata Name="FileName" Value="TestDrive:\DacPac\ReferencedDacPac2.dacpac" />
                <Metadata Name="LogicalName" Value="ReferencedDacPac2.dacpac" />
            </CustomData>     
        </Header>
    </DataSchemaModel>
"@ | out-File $DacpacReferencedModel

        Get-ChildItem -Path $DacpacReferencedOrigin, $DacpacReferencedModel | Compress-Archive -DestinationPath $DacpacReferencedzip
        move-item $DacpacReferencedzip $DacpacReferenced -Force #this is needed as powershell < 6 doesn't allow compress archive to anything other than a .zip

        $DacpacReferenced2 = "TestDrive:\DacPac\ReferencedDacPac2.dacpac"
        $DacpacReferenced2zip = "$DacpacReferenced2.zip"
        $DacpacReferenced2Origin = "TestDrive:\ReferencedDacPac2\Origin.xml"
        new-item $DacpacReferenced2Origin -type file -force
        @"
<DacOrigin xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">
    <Checksums>
        <Checksum Uri="/model.xml">abcd</Checksum>
    </Checksums>
</DacOrigin>
"@ | out-File $DacpacReferenced2Origin

        $DacpacReferenced2Model = "TestDrive:\ReferencedDacPac2\model.xml"
        new-item $DacpacReferenced2Model -type file -force
        @"
<DataSchemaModel xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">     
</DataSchemaModel>
"@ | out-File $DacpacReferenced2Model

        Get-ChildItem -Path $DacpacReferenced2Origin, $DacpacReferenced2Model | Compress-Archive -DestinationPath $DacpacReferenced2zip
        move-item $DacpacReferenced2zip $DacpacReferenced2 -Force #this is needed as powershell < 6 doesn't allow compress archive to anything other than a .zip        

        Get-DacPacHash (Get-Item $Dacpac).FullName | Should -be "abcd12345678"
    }    


    It 'given a dacpac with hash of 1234 which references a different db dacpac with a hash of 5678 should return the hash (1234) from both dacpacs' {

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

        $DacpacModel = "TestDrive:\DacPac\model.xml"
        new-item $DacpacModel -type file -force
        @"
<DataSchemaModel xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">     
    <Header>
        <CustomData Category="Reference" Type="SqlSchema">
            <Metadata Name="FileName" Value="TestDrive:\DacPac\ReferencedDacPac.dacpac" />
            <Metadata Name="LogicalName" Value="ReferencedDacPac.dacpac" />       
            <Metadata Name="ExternalParts" Value="[(Referenced)]" />
        </CustomData>     
    </Header>
</DataSchemaModel>
"@ | out-File $DacpacModel
        Get-ChildItem -Path $DacpacOrigin, $DacpacModel | Compress-Archive -DestinationPath $Dacpaczip
        move-item $Dacpaczip $Dacpac -Force #this is needed as powershell < 6 doesn't allow compress archive to anything other than a .zip

        $DacpacReferenced = "TestDrive:\DacPac\ReferencedDacPac.dacpac"
        $DacpacReferencedzip = "$DacpacReferenced.zip"
        $DacpacReferencedOrigin = "TestDrive:\ReferencedDacPac\Origin.xml"
        new-item $DacpacReferencedOrigin -type file -force
        @"
<DacOrigin xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">
    <Checksums>
        <Checksum Uri="/model.xml">5678</Checksum>
    </Checksums>
</DacOrigin>
"@ | out-File $DacpacReferencedOrigin

        $DacpacReferencedModel = "TestDrive:\ReferencedDacPac\model.xml"
        new-item $DacpacReferencedModel -type file -force
        @"
<DataSchemaModel xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">     
</DataSchemaModel>
"@ | out-File $DacpacReferencedModel

        Get-ChildItem -Path $DacpacReferencedOrigin, $DacpacReferencedModel | Compress-Archive -DestinationPath $DacpacReferencedzip
        move-item $DacpacReferencedzip $DacpacReferenced -Force #this is needed as powershell < 6 doesn't allow compress archive to anything other than a .zip
        
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
        $DacpacModel = "TestDrive:\DacPac\model.xml"
        new-item $DacpacModel -type file -force
        @"
<DataSchemaModel xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">     
</DataSchemaModel>
"@ | out-File $DacpacModel        
        Get-ChildItem -Path  $DacpacModel | Compress-Archive -DestinationPath $Dacpaczip -Force
        move-item $Dacpaczip $Dacpac -Force

        {Get-DacPacHash (Get-Item $Dacpac).FullName} | Should -Throw  "Can't find the Origin.xml file in the dacpac, would guess this isn't a dacpac"
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
