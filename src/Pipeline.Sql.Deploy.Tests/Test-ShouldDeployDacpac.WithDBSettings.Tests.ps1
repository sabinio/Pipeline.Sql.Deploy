param(
    [parameter(Mandatory = $false)] $serverName,
    $ModulePath,
    $ProjectName
)
BeforeDiscovery{
    Write-Verbose "Module path Beforedisco - $ModulePath"-verbose
}
BeforeAll {
	Set-StrictMode -Version 1.0
    if (-not (Test-path  Variable:\ProjectName)) { $ProjectName = (get-item $PSScriptRoot).basename -replace ".tests", "" }
    $CommandName = [IO.Path]::GetFileName($PSCommandPath).Replace(".Tests.ps1", "")
    
    if (-not (Test-path  Variable:\ModulePath) -or "$ModulePath" -eq "") {$ModulePath = "$PSScriptRoot\..\$ProjectName.module" }
    #. $ModuleBase\functions\$CommandName
    Write-Verbose "Module path Beforeall after - $ModulePath" -verbose

    get-module $ProjectName | Remove-Module -Force
    Get-ChildItem ([System.IO.Path]::Combine($ModulePath,"Functions","*.ps1")) -Recurse | ForEach-Object{
         Write-Verbose "loading $_" -Verbose;
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

        It "Given the settings don't exist in the DB, result Should -Be true" {
            Mock Test-IsPreviousDeploySettingsFileMissing { $true } 
            Mock Test-DatabaseExists {$true}
            $settings = @{TargetServer = "."; TargetDatabaseName = "foo" }
            Mock Get-DeploySettingsfromDB {$null}
            
            Test-ShouldDeployDacpac -settings $settings -dacpacFile $dacpacPath -publishfile $publishFile | Should -Be $true
            
            Should -invoke Test-IsPreviousDeploySettingsFileMissing -Exactly 0   #DB Settings no file passed
        }
    }
}
Describe "test a"{
    BeforeAll {
        $dacpacPath = "TestDrive:\test.dacpac"
        Set-Content $dacpacPath -value "testdacpac"
        $publishFile = "TestDrive:\publish.xml"
        Set-Content $publishFile -value "testdacpac" 
    }
    Context 'settings file exists' {                
        It "Given the deploy settings have changed, result Should -Be true" {
            $settings = @{TargetServer = "."; TargetDatabaseName = "foo" }

            Mock Test-IsPreviousDeploySettingsFileMissing { $true } 
            Mock Test-DatabaseExists {$true}

            Mock Get-DeploySettingsfromDB { @{settings=@{TargetServer = "."; TargetDatabaseName = "foo2" }}}
            
            Test-ShouldDeployDacpac -settings $settings -dacpacFile $dacpacPath -publishfile $publishFile | Should -Be $true
            
            Should -invoke Test-IsPreviousDeploySettingsFileMissing -Exactly 0   #DB Settings no file passed

        }
        It "Given the deploy settings have  NOT changed, result Should -Be false" {
            $settings = @{TargetServer = "."; TargetDatabaseName = "foo" }

            Mock Test-IsPreviousDeploySettingsFileMissing { $true } 
            Mock Test-DatabaseExists {$true}

            Mock Get-DeploySettingsFromDB { @{lastDeployDate=(Get-Date -Year 2200 -Month 1 -Day 1);settings = $settings }}
    
            Test-ShouldDeployDacpac -settings $settings -dacpacFile $dacpacPath -publishfile $publishFile | Should -Be $false
            
            Should -invoke Test-IsPreviousDeploySettingsFileMissing -Exactly 0   #DB Settings no file passed
        }
        It "Given the deploy settings have changed and deployDate is later, result Should -Be true" {
            $settings = @{TargetServer = "."; TargetDatabaseName = "foo" }

            Mock Test-IsPreviousDeploySettingsFileMissing { $true } 
            Mock Test-DatabaseExists {$true}

            Mock Get-DeploySettingsFromDB { @{lastDeployDate=(Get-Date -Year 2200 -Month 1 -Day 1);settings = @{TargetServer = "."; TargetDatabaseName = "foo2" } }}
    
            Test-ShouldDeployDacpac -settings $settings -dacpacFile $dacpacPath -publishfile $publishFile | Should -Be $true
            
            Should -invoke Test-IsPreviousDeploySettingsFileMissing -Exactly 0   #DB Settings no file passed
        }
    }
}
Describe "test b"{
    BeforeAll {
        $dacpacPath = "TestDrive:\test.dacpac"
        Set-Content $dacpacPath -value "testdacpac"
        $publishFile = "TestDrive:\publish.xml"
        Set-Content $publishFile -value "testdacpac" 
    }

    Context "test" {  
        It "Given database found deployguard returns true if no deployment table exists" {
            Mock Test-IsPreviousDeploySettingsFileMissing { $false } 
            Mock Test-HaveDeploySettingsChangedSinceLastDeploy { $false }
  
            Mock Test-DatabaseExists {$true}
            Mock Get-DeploySettingsFromDB {throw "no table"}

            $settings = @{TargetServer = "."; TargetDatabaseName = "tabledoesnotexist" }    
            Test-ShouldDeployDacpac  -settings $settings -dacpacFile $dacpacPath -publishfile $publishFile| Should -Be $true
           
        }
    }       
}

