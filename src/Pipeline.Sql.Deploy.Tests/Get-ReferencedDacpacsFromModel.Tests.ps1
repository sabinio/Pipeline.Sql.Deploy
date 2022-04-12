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

Describe 'Get-ReferencedDacpacsFromModel' {
    It 'given the xml from model.xml which contains no referenced dacpacs; returns empty array' {
        $modelxml = @"
<DataSchemaModel xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">    
    <header>
        <CustomData Category="Reference" Type="NotSqlSchema">
        </CustomData>  
    </header>
    <model>
        <Element Type="SqlTable" Name="[dbo].[Account]">
        </Element>
    </model>
</DataSchemaModel>
"@  
        [xml]$dacpacXml = New-Object xml
        $dacpacXml= [xml]$modelxml 
        $expected = @();
        
        Get-ReferencedDacpacsFromModel -modelxml $modelxml | Should -be $expected
    }

    It 'given the xml from model.xml which contains one referenced external dacpac; returns empty array' {    

        $modelxml = @"
<DataSchemaModel xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">    
    <header>
        <CustomData Category="Reference" Type="SqlSchema">
            <Metadata Name="FileName" Value="TestDrive:\DacPac\ReferencedDacPac.dacpac" />
            <Metadata Name="LogicalName" Value="ReferencedDacPac.dacpac" />
            <Metadata Name="ExternalParts" Value="[(Referenced)]" />
        </CustomData>  
    </header>
</DataSchemaModel>
"@    
        [xml]$dacpacXml = New-Object xml
        $dacpacXml= [xml]$modelxml 
        $expected = @();
        
        Get-ReferencedDacpacsFromModel -modelxml $modelxml | Should -be $expected
    }
    It 'given the xml from model.xml which contains one referenced dacpac; returns array with one filename' {    
        $modelxml = @"
<DataSchemaModel xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">    
    <header>
        <CustomData Category="Reference" Type="SqlSchema">
            <Metadata Name="FileName" Value="TestDrive:\DacPac\ReferencedDacPac.dacpac" />
            <Metadata Name="LogicalName" Value="ReferencedDacPac.dacpac" />
        </CustomData>  
    </header>
</DataSchemaModel>
"@    
        [xml]$dacpacXml = New-Object xml
        $dacpacXml= [xml]$modelxml 
        $expected = @("ReferencedDacPac.dacpac");
        
        Get-ReferencedDacpacsFromModel -modelxml $modelxml | Should -be $expected        
    }

    It 'given the xml from model.xml which contains two referenced dacpac; returns array with two filenames' {    
        $modelxml = @"
<DataSchemaModel xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">    
    <header>
        <CustomData Category="Reference" Type="SqlSchema">
            <Metadata Name="FileName" Value="TestDrive:\DacPac\ReferencedDacPac.dacpac" />
            <Metadata Name="LogicalName" Value="ReferencedDacPac.dacpac" />
        </CustomData>  
        <CustomData Category="Reference" Type="SqlSchema">
            <Metadata Name="FileName" Value="TestDrive:\DacPac\ReferencedDacPac2.dacpac" />
            <Metadata Name="LogicalName" Value="ReferencedDacPac2.dacpac" />
        </CustomData>          
    </header>
</DataSchemaModel>
"@    
        [xml]$dacpacXml = New-Object xml
        $dacpacXml= [xml]$modelxml 
        $expected = @("ReferencedDacPac.dacpac","ReferencedDacPac2.dacpac");
        
        Get-ReferencedDacpacsFromModel -modelxml $modelxml | Should -be $expected   
        
    }

    It 'given the xml from model.xml which contains three referenced dacpacs but one is external; returns array with two filenames' {    
        $modelxml = @"
<DataSchemaModel xmlns="http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02">    
    <header>
        <CustomData Category="Reference" Type="SqlSchema">
            <Metadata Name="FileName" Value="TestDrive:\DacPac\ReferencedDacPac.dacpac" />
            <Metadata Name="LogicalName" Value="ReferencedDacPac.dacpac" />
        </CustomData>  
        <CustomData Category="Reference" Type="SqlSchema">
            <Metadata Name="FileName" Value="TestDrive:\DacPac\ReferencedDacPac2.dacpac" />
            <Metadata Name="LogicalName" Value="ReferencedDacPac2.dacpac" />
        </CustomData>     
        <CustomData Category="Reference" Type="SqlSchema">
            <Metadata Name="FileName" Value="TestDrive:\DacPac\Master.dacpac" />
            <Metadata Name="LogicalName" Value="Master.dacpac" />
            <Metadata Name="ExternalParts" Value="[(master)]" />
        </CustomData>               
    </header>
</DataSchemaModel>
"@    
        [xml]$dacpacXml = New-Object xml
        $dacpacXml= [xml]$modelxml 
        $expected = @("ReferencedDacPac.dacpac","ReferencedDacPac2.dacpac");
        
        Get-ReferencedDacpacsFromModel -modelxml $modelxml | Should -be $expected   
        
    }

}