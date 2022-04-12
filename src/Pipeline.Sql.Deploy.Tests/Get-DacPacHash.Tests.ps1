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

}

Describe 'Get-DacPacHash' {
    It 'given a dacpac model element with hash of DF7C934283E27966F7C0C9A57C443D06EE2132724AEBA63FA1CD5281DDF1DD08 should return the hash (DF7C934283E27966F7C0C9A57C443D06EE2132724AEBA63FA1CD5281DDF1DD08) from a dacpac' {

        $Dacpac = "TestDrive:\DacPac\TestDacPac.dacpac"
        $Dacpaczip = "$dacpac.zip"
        $DacpacModel = "TestDrive:\DacPac\model.xml"
        new-item $DacpacModel -type file -force
        @"
<DataSchemaModel xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">    
    <header>
        <CustomData Category="Reference" Type="SqlSchema">
            <Metadata Name="FileName" Value="TestDrive:\DacPac\ReferencedDacPac.dacpac" />
            <Metadata Name="LogicalName" Value="ReferencedDacPac.dacpac" />
            <Metadata Name="ExternalParts" Value="[(Referenced)]" />
        </CustomData>  
    </header>
    <model>
        <Element Type="SqlTable" Name="[dbo].[Account]">
        </Element>
    </model>
</DataSchemaModel>
"@ | out-File $DacpacModel
        Get-ChildItem -Path  $DacpacModel | Compress-Archive -DestinationPath $Dacpaczip
        move-item $Dacpaczip $Dacpac -Force #this is needed as powershell < 6 doesn't allow compress archive to anything other than a .zip
    
        Get-DacPacHash (Get-Item $Dacpac).FullName | Should -be "DF7C934283E27966F7C0C9A57C443D06EE2132724AEBA63FA1CD5281DDF1DD08"
    }

    It 'given a dacpac with identical model element with hash of DF7C934283E27966F7C0C9A57C443D06EE2132724AEBA63FA1CD5281DDF1DD08 but different header element should still return the hash (DF7C934283E27966F7C0C9A57C443D06EE2132724AEBA63FA1CD5281DDF1DD08) ' {

        $Dacpac = "TestDrive:\DacPac\TestDacPac.dacpac"
        $Dacpaczip = "$dacpac.zip"
        $DacpacModel = "TestDrive:\DacPac\model.xml"
        new-item $DacpacModel -type file -force
        @"
<DataSchemaModel xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">    
    <header>
        <CustomData Category="Reference" Type="SqlSchema">
            <Metadata Name="FileName" Value="TestDrive:\DacPac\DifferentReferencedDacPac.dacpac" />
            <Metadata Name="LogicalName" Value="DifferentReferencedDacPac.dacpac" />
            <Metadata Name="ExternalParts" Value="[(Referenced)]" />
        </CustomData>  
    </header>
    <model>
        <Element Type="SqlTable" Name="[dbo].[Account]">
        </Element>
    </model>
</DataSchemaModel>
"@ | out-File $DacpacModel
        Get-ChildItem -Path  $DacpacModel | Compress-Archive -DestinationPath $Dacpaczip
        move-item $Dacpaczip $Dacpac -Force #this is needed as powershell < 6 doesn't allow compress archive to anything other than a .zip
    
        Get-DacPacHash (Get-Item $Dacpac).FullName | Should -be "DF7C934283E27966F7C0C9A57C443D06EE2132724AEBA63FA1CD5281DDF1DD08"
    }

    It 'given a dacpac with hash of DF7C934283E27966F7C0C9A57C443D06EE2132724AEBA63FA1CD5281DDF1DD08 and a predeploy script that returns hash 206ECD474E2920B4AFAB073FA6D10C1B9371640E23125DCA8092E93FF6457C42 ' {

        $Dacpac = "TestDrive:\DacPac\TestDacPac.dacpac"
        $Dacpaczip = "$dacpac.zip"

        $DacpacModel = "TestDrive:\DacPac\model.xml"
        new-item $DacpacModel -type file -force
        @"
        <DataSchemaModel xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">    
        <model>
            <Element Type="SqlTable" Name="[dbo].[Account]">
            </Element>
        </model>
    </DataSchemaModel>
"@ | out-File $DacpacModel

        $PredeployFile = "TestDrive:\DacPac\predeploy.sql"
        new-item $PredeployFile -type file -force
        $Predeploy = @"
            SELECT 'DF7C934283E27966F7A443D06EE2132724AEBA63FA1CD5281DDF1DD08'
print "Pre deploy script"
"@ 
        Set-Content $PredeployFile -Value $Predeploy -Encoding utf8 -NoNewline

        $stream = [IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($Predeploy))
        $predeployhash = Get-FileHash -InputStream $stream -Algorithm SHA256
        $stream.Dispose()

        Get-ChildItem -Path  $DacpacModel, $PredeployFile | Compress-Archive -DestinationPath $Dacpaczip
        move-item $Dacpaczip $Dacpac -Force #this is needed as powershell < 6 doesn't allow compress archive to anything other than a .zip

        $predeployhash.hash | Should -be "684E4C1A05483E1FAFF6CCE543432FB14570286CEDAADEE314964706B5A31EC4"
        Get-DacPacHash (Get-Item $Dacpac).FullName | Should -be "DF7C934283E27966F7C0C9A57C443D06EE2132724AEBA63FA1CD5281DDF1DD08$($predeployhash.hash)"
    }
  

    It 'given a dacpac with hash of DF7C934283E27966F7C0C9A57C443D06EE2132724AEBA63FA1CD5281DDF1DD08 and a postdeploy script that returns hash 7AE1A6B52631A1E5DBBC0D37B50182F90FD05A56096B0E8E19AE3849E249FC49 then should return the combined hash' {

        $Dacpac = "TestDrive:\DacPac\TestDacPac.dacpac"
        $Dacpaczip = "$dacpac.zip"
        $DacpacModel = "TestDrive:\DacPac\model.xml"
        new-item $DacpacModel -type file -force
        @"
        <DataSchemaModel xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">    
        <model>
            <Element Type="SqlTable" Name="[dbo].[Account]">
            </Element>
        </model>
    </DataSchemaModel>
"@ | out-File $DacpacModel

        $Postdeploy = "TestDrive:\DacPac\postdeploy.sql"
        new-item $Postdeploy -type file -force
@"
      print "Post deploy script"
"@ | out-File $Postdeploy

        Get-ChildItem -Path $DacpacModel, $Postdeploy | Compress-Archive -DestinationPath $Dacpaczip
        move-item $Dacpaczip $Dacpac -Force #this is needed as powershell < 6 doesn't allow compress archive to anything other than a .zip

        Get-DacPacHash (Get-Item $Dacpac).FullName | Should -be "DF7C934283E27966F7C0C9A57C443D06EE2132724AEBA63FA1CD5281DDF1DD08089EFE9CBE8FA8F0A51FB48663F84BBD7DFEE4BBD3429490D5FBC5BD7BCFA45B"
    }


    It 'given a dacpac with hash of DF7C934283E27966F7C0C9A57C443D06EE2132724AEBA63FA1CD5281DDF1DD08 and a predeploy script and a postdeploy script  then should return the combined hash' {

        $Dacpac = "TestDrive:\DacPac\TestDacPac.dacpac"
        $Dacpaczip = "$dacpac.zip"

        $DacpacModel = "TestDrive:\DacPac\model.xml"
        new-item $DacpacModel -type file -force
        @"
        <DataSchemaModel xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">    
        <model>
            <Element Type="SqlTable" Name="[dbo].[Account]">
            </Element>
        </model>
    </DataSchemaModel>
"@ | out-File $DacpacModel

        $Postdeploy = "TestDrive:\DacPac\postdeploy.sql"
        new-item $Postdeploy -type file -force
@"
      print "Post deploy script"
"@ | out-File $Postdeploy

        $Predeploy = "TestDrive:\DacPac\predeploy.sql"
        new-item $Predeploy -type file -force
@"
      print "Pre deploy script"
"@ | out-File $Predeploy

        
        Get-ChildItem -Path $DacpacModel, $Postdeploy ,$Predeploy| Compress-Archive -DestinationPath $Dacpaczip
        move-item $Dacpaczip $Dacpac -Force #this is needed as powershell < 6 doesn't allow compress archive to anything other than a .zip
        Get-DacPacHash (Get-Item $Dacpac).FullName | Should -be "DF7C934283E27966F7C0C9A57C443D06EE2132724AEBA63FA1CD5281DDF1DD08089EFE9CBE8FA8F0A51FB48663F84BBD7DFEE4BBD3429490D5FBC5BD7BCFA45BDB3DB5596BB699EC0A32A15EFE6B0FD6E5B392710F33823EF7BBF728012C0479"
        #Assert-MockCalled Get-FileHash -Exactly 2
    }

    It 'given a changes to pre and post deploy ensure the hash is different' {

        function generate-dacpac {
            param ($dacpac, $content)
            
            $Dacpaczip = "$dacpac.zip"

            $DacpacModel = "TestDrive:\DacPac\model.xml"
            new-item $DacpacModel -type file -force
@"
            <DataSchemaModel xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">    
            <model>
                <Element Type="SqlTable" Name="[dbo].[Account]">
                </Element>
            </model>
        </DataSchemaModel>
"@ | out-File $DacpacModel

            $Postdeploy = "TestDrive:\DacPac\postdeploy.sql"
            new-item $Postdeploy -type file -force
            $content| out-File $Postdeploy

        Get-ChildItem -Path $DacpacModel, $Postdeploy | Compress-Archive -DestinationPath $Dacpaczip
        move-item $Dacpaczip $Dacpac -Force #this is needed as powershell < 6 doesn't allow compress archive to anything other than a .zip
        }

        $Dacpac = "TestDrive:\DacPac\TestDacPac.dacpac"
        generate-dacpac -dacpac $dacpac -content "Some predeploy script"
        $hash1 = get-dacpachash (Get-Item $Dacpac).FullName
        
        generate-dacpac -dacpac $dacpac -content "Some other script"
        $hash2 = get-dacpachash (Get-Item $Dacpac).FullName

        $hash1 | should -not -be $null
        $hash1 | should -not -be ""
        $hash1 | should -not -be $hash2
    }


    It 'given a dacpac with hash of DF7C934283E27966F7C0C9A57C443D06EE2132724AEBA63FA1CD5281DDF1DD08 which references a same db dacpac with a hash of 13FD99548209FBD167F6693965A1161C27F12DB7E8CEBF4341007D1506B05AE7 should return the combined hash from both dacpacs' {

        $Dacpac = "TestDrive:\DacPac\TestDacPac.dacpac"
        $Dacpaczip = "$dacpac.zip"

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
    <model>
        <Element Type="SqlTable" Name="[dbo].[Account]">
        </Element>
    </model>    
</DataSchemaModel>
"@ | out-File $DacpacModel

        Get-ChildItem -Path $DacpacModel | Compress-Archive -DestinationPath $Dacpaczip
        move-item $Dacpaczip $Dacpac -Force #this is needed as powershell < 6 doesn't allow compress archive to anything other than a .zip

        $DacpacReferenced = "TestDrive:\DacPac\ReferencedDacPac.dacpac"
        $DacpacReferencedzip = "$DacpacReferenced.zip"

        $DacpacReferencedModel = "TestDrive:\ReferencedDacPac\model.xml"
        new-item $DacpacReferencedModel -type file -force
        @"
<DataSchemaModel xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">    
    <model>
        <Element Type="SqlTable" Name="[dbo].[TblAccount]">
        </Element>
    </model>  
</DataSchemaModel>
"@ | out-File $DacpacReferencedModel

        Get-ChildItem -Path $DacpacReferencedModel | Compress-Archive -DestinationPath $DacpacReferencedzip
        move-item $DacpacReferencedzip $DacpacReferenced -Force #this is needed as powershell < 6 doesn't allow compress archive to anything other than a .zip
    
        Get-DacPacHash (Get-Item $Dacpac).FullName | Should -be "DF7C934283E27966F7C0C9A57C443D06EE2132724AEBA63FA1CD5281DDF1DD0813FD99548209FBD167F6693965A1161C27F12DB7E8CEBF4341007D1506B05AE7"
    }    

    It 'given a dacpac which references a dacpac which in turn references a third dacpac, combined hash should be obtains from all three dacpacs' {

        $Dacpac = "TestDrive:\DacPac\TestDacPac.dacpac"
        $Dacpaczip = "$dacpac.zip"

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
    <model>
        <Element Type="SqlTable" Name="[dbo].[Account]">
        </Element>
    </model>      
</DataSchemaModel>
"@ | out-File $DacpacModel

        Get-ChildItem -Path $DacpacModel | Compress-Archive -DestinationPath $Dacpaczip
        move-item $Dacpaczip $Dacpac -Force #this is needed as powershell < 6 doesn't allow compress archive to anything other than a .zip

        $DacpacReferenced = "TestDrive:\DacPac\ReferencedDacPac.dacpac"
        $DacpacReferencedzip = "$DacpacReferenced.zip"


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
    <model>
        <Element Type="SqlTable" Name="[dbo].[Account2]">
        </Element>
    </model>          
</DataSchemaModel>
"@ | out-File $DacpacReferencedModel

        Get-ChildItem -Path  $DacpacReferencedModel | Compress-Archive -DestinationPath $DacpacReferencedzip
        move-item $DacpacReferencedzip $DacpacReferenced -Force #this is needed as powershell < 6 doesn't allow compress archive to anything other than a .zip

        $DacpacReferenced2 = "TestDrive:\DacPac\ReferencedDacPac2.dacpac"
        $DacpacReferenced2zip = "$DacpacReferenced2.zip"

        $DacpacReferenced2Model = "TestDrive:\ReferencedDacPac2\model.xml"
        new-item $DacpacReferenced2Model -type file -force
        @"
<DataSchemaModel xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">  
    <model>
        <Element Type="SqlTable" Name="[dbo].[Account3]">
        </Element>
    </model>     
</DataSchemaModel>
"@ | out-File $DacpacReferenced2Model

        Get-ChildItem -Path $DacpacReferenced2Model | Compress-Archive -DestinationPath $DacpacReferenced2zip
        move-item $DacpacReferenced2zip $DacpacReferenced2 -Force #this is needed as powershell < 6 doesn't allow compress archive to anything other than a .zip        

        Get-DacPacHash (Get-Item $Dacpac).FullName | Should -be "DF7C934283E27966F7C0C9A57C443D06EE2132724AEBA63FA1CD5281DDF1DD08D3EAFE9F45F5881ADD3669155556885AA5C8E5E0D45E58F2DF1D0FB8CABB7690B0DE0AC154D8696BD8992F9E274BBCD476E2B836D20183730D5688C124B3B385"
    }    

    It 'given a dacpac with hash of DF7C934283E27966F7C0C9A57C443D06EE2132724AEBA63FA1CD5281DDF1DD08 which references a different db dacpac with a hash of DF7C934283E27966F7C0C9A57C443D06EE2132724AEBA63FA1CD5281DDF1DD08 should return the hash (1234) from both dacpacs' {

        $Dacpac = "TestDrive:\DacPac\TestDacPac.dacpac"
        $Dacpaczip = "$dacpac.zip"

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
    <model>
        <Element Type="SqlTable" Name="[dbo].[Account]">
        </Element>
    </model>      
</DataSchemaModel>
"@ | out-File $DacpacModel
        Get-ChildItem -Path $DacpacModel | Compress-Archive -DestinationPath $Dacpaczip
        move-item $Dacpaczip $Dacpac -Force #this is needed as powershell < 6 doesn't allow compress archive to anything other than a .zip

        $DacpacReferenced = "TestDrive:\DacPac\ReferencedDacPac.dacpac"
        $DacpacReferencedzip = "$DacpacReferenced.zip"

        $DacpacReferencedModel = "TestDrive:\ReferencedDacPac\model.xml"
        new-item $DacpacReferencedModel -type file -force
        @"
<DataSchemaModel xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">  
    <model>
        <Element Type="SqlTable" Name="[dbo].[Account2]">
        </Element>
    </model>     
</DataSchemaModel>
"@ | out-File $DacpacReferencedModel

        Get-ChildItem -Path  $DacpacReferencedModel | Compress-Archive -DestinationPath $DacpacReferencedzip
        move-item $DacpacReferencedzip $DacpacReferenced -Force #this is needed as powershell < 6 doesn't allow compress archive to anything other than a .zip
        
        Get-DacPacHash (Get-Item $Dacpac).FullName | Should -be "DF7C934283E27966F7C0C9A57C443D06EE2132724AEBA63FA1CD5281DDF1DD08"
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
