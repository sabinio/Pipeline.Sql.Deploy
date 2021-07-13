param(
    [parameter(Mandatory = $false)] $serverName,
    $ModulePath,
    $ProjectName
)
BeforeAll {
    Set-StrictMode -Version 1.0
    $ErrorActionPreference="stop"

    if (-not (Test-path  Variable:\ProjectName)) { $ProjectName = (get-item $PSScriptRoot).basename -replace ".tests", "" }
    $CommandName = [IO.Path]::GetFileName($PSCommandPath).Replace(".Tests.ps1", "")
    
    if (-not (Test-path  Variable:\ModulePath) -or "$ModulePath" -eq "") { $ModulePath = "$PSScriptRoot\..\$ProjectName.module" }
    #. $ModuleBase\functions\$CommandName
    Write-Verbose "Module path Beforeall after - $ModulePath" 

    get-module $ProjectName | Remove-Module -Force
    Get-ChildItem ([System.IO.Path]::Combine($ModulePath, "Functions", "*.ps1")) -Recurse | ForEach-Object {
        Write-Verbose "loading $_";
        . $_.FullName
    }
}
Describe 'deploy-guard' {
    BeforeAll {
        $dacpacPath = "TestDrive:\test.dacpac"
        Set-Content $dacpacPath -value "testdacpac"
        $publishFile = "TestDrive:\publish.xml"
        Set-Content $publishFile -value "testdacpac" 
    }

    Context 'settings file missing' {

        It "Given the settingsfile does not exist, result Should -Be true" {
            Mock Test-IsPreviousDeploySettingsFileMissing { $true } 
            Mock Test-DatabaseExists { $true }
            $settings = @{TargetServer = "."; TargetDatabaseName = "foo" }
                
            Test-ShouldDeployDacpac -settings $settings -dacpacFile $dacpacPath -publishfile $publishFile -DBDeploySettingsFile "sdfsd" | Should -Be $true
            
            Assert-MockCalled Test-IsPreviousDeploySettingsFileMissing -Exactly 1    
        }
    }

    Context 'settings file exists' {               
        BeforeAll {
            $dacpacPath = "TestDrive:\test.dacpac"
            Set-Content $dacpacPath -value "testdacpac"
            $publishFile = "TestDrive:\publish.xml"
            Set-Content $publishFile -value "testdacpac" 
        } 
        It "Given the deploy settings have changed, result Should -Be true" {
            Mock Test-IsPreviousDeploySettingsFileMissing { $false } 
            Mock Test-DatabaseExists { $true }
           
            $settings = @{TargetServer = "."; TargetDatabaseName = "foo" }
            Mock Get-DeploySettingsFromFile { @{} }

            $result = Test-ShouldDeployDacpac -settings $settings -dacpacFile $dacpacPath -publishfile $publishFile -DBDeploySettingsFile "Somefile"-verbose
                
            $result | Should -Be $true
            
            Should -Invoke Test-IsPreviousDeploySettingsFileMissing #-Exactly 1 

        }
    }

    Context 'Test-ShouldDeployDacpac' {
        BeforeAll {
            $dacpacPath = "TestDrive:\test.dacpac"
            Set-Content $dacpacPath -value "testdacpac"
            $publishFile = "TestDrive:\publish.xml"
            Set-Content $publishFile -value "testdacpac" 
        }
    
        It "Given the deploy settings have changed, result Should -Be true" {
                
            $localsettings = @{TargetServer = "."; TargetDatabaseName = "foo"; variables = "sdfsfs" }
            Mock Test-DatabaseExists { $true }
            Mock Get-DeploySettingsFromFile { $localsettings }
            Mock Test-IsPreviousDeploySettingsFileMissing { $false } 
            
            $result = Test-ShouldDeployDacpac -settings $localsettings -dacpacFile $dacpacPath -publishfile $publishFile -DBDeploySettingsFile "settings.json"
                
            Assert-MockCalled Test-IsPreviousDeploySettingsFileMissing -Exactly 1 -Scope It
            $result | Should -Be $true
    
        }
    }
    
    Context 'settings file exists, settings not changed' {
       
        It "Given database not found, deployguard returns true" {
            Mock Test-DatabaseExists { $false }
           
            Mock Test-IsPreviousDeploySettingsFileMissing { $false } 
            Mock Test-HaveDeploySettingsChangedSinceLastDeploy { $false }
    
            $settings = @{TargetServerName = "."; TargetDatabaseName = "dbdoesnotexist" }
            $result = Test-ShouldDeployDacpac -settings $settings -dacpacFile $dacpacPath -publishfile $publishFile -verbose  -DBDeploySettingsFile "something.json"
                
            $result | Should -Be $true
            Assert-MockCalled Test-DatabaseExists -Exactly 1 -Scope It
        }
    }
    Context "test" {  
        It "Given database found deployguard returns true if no deployment table exists" {
            Mock Test-IsPreviousDeploySettingsFileMissing { $false } 
            Mock Test-HaveDeploySettingsChangedSinceLastDeploy { $false }

            $settings = @{TargetServer = "."; TargetDatabaseName = "tabledoesnotexist" }    
            Mock Get-DeploySettingsFromFile { $settings }
          
            Mock Get-DeploySettingsFromDB { throw "table doesn't exist"}
            Mock Test-DatabaseExists { $true }

            $result = Test-ShouldDeployDacpac  -settings $settings -dacpacFile $dacpacPath -publishfile $publishFile -Verbose  -DBDeploySettingsFile "something.json"
                
            $result | Should -Be $true
            Should -invoke Get-DeploySettingsFromDB -Exactly 1 -Scope It
        }
    }
    Context "Deploy Settings File" {
        It "Given database found deployguard returns false if deployment table exists with later date than LastWriteTime of settings file" {
            $settings = @{TargetServer = "."; TargetDatabaseName = "randomName1" }    
           
            Mock Get-DeploySettingsFromFile { $settings }
            Mock Test-IsPreviousDeploySettingsFileMissing { $false } 
            Mock Test-DatabaseExists { $true }
            Mock Get-Item -ParameterFilter { $Path -eq "bob.json" } { [PSCustomObject]@{LastWriteTimeUtc = (get-date -Year 2020 -Month 1 -day 1) } }

            Mock Get-DeploySettingsFromDB { @{lastDeployDate=(Get-Date -Year 2200 -Month 1 -Day 1) }}
    
            $result = Test-ShouldDeployDacpac  -settings $settings -dacpacFile $dacpacPath -publishfile $publishFile  -DBDeploySettingsFile "bob.json" -Verbose
                
            $result | Should -Be $false
        }
            
        It "Given database found and a previous old deployment deployguard returns true if dacpac is newer" {
            $settings = @{TargetServer = "."; TargetDatabaseName = "randomName2" }    
           
            Mock Get-DeploySettingsFromFile { $settings }
            Mock Test-IsPreviousDeploySettingsFileMissing { $false } 
            Mock Test-DatabaseExists { $true }

            Mock Get-DeploySettingsFromDB { @{lastDeployDate=(Get-Date -Year 1900 -Month 1 -Day 1) }}
            $result = Test-ShouldDeployDacpac  -settings $settings -dacpacFile $dacpacPath -publishfile $publishFile   -DBDeploySettingsFile "something.json"
                
            $result | Should -Be $true
        }        
    }
}

