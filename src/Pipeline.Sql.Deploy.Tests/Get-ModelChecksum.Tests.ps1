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

Describe 'Get-ModelChecksum' {
    It 'returns the correct checksum of only the model element' {
        $modelxml = @"
<DataSchemaModel xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">    
    <header>
        <CustomData Category="Reference" Type="NotSqlSchema">
        </CustomData>  
    </header>
%modelelement%
</DataSchemaModel>
"@  

$modelelement = @"
    <model xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">
        <Element Type="SqlTable" Name="[dbo].[Account]">
        </Element>
    </model>
"@
        [xml]$modelelementxml = New-Object xml
        $modelelementxml= [xml]$modelelement
        $expectedHash = (Get-FileHash -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($modelelementxml.OuterXml)))).Hash;

        [xml]$xmlTotest = New-Object xml
        $xmlTotest= [xml]$($modelxml -replace "%modelelement%", $modelelement) 
        
        Get-ModelChecksum -modelxml $xmlTotest | Should -be $expectedHash
    }

    It 'given a model.xml that not got a model element return an error' {
        $modelxml = @"
<DataSchemaModel xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">    
    <header>
        <CustomData Category="Reference" Type="NotSqlSchema">
        </CustomData>  
    </header>
</DataSchemaModel>
"@  
        [xml]$xmlTotest = New-Object xml
        $xmlTotest= [xml]$modelxml 

        {Get-ModelChecksum -modelxml $xmlTotest} |  Should -Throw  "Can't find  model element correct location in the model.xml, not possible to return a checksum"
    }   
}