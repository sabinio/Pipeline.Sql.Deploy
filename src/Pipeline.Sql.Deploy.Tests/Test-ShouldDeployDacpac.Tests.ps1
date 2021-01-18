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

    Remove-Module $ProjectName -ErrorAction SilentlyContinue
    gci (Join-path $ModulePath "Functions" "*.ps1") | %{ Write-Verbose "loading $_" -Verbose;
    . $_}
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
            $settings = @{TargetServer = "."; TargetDatabaseName = "foo" }
                
            $result = Test-ShouldDeployDacpac -settings $settings -dacpacFile $dacpacPath -publishfile $publishFile 
                
            $result | Should -Be $true
    
            Assert-MockCalled Test-IsPreviousDeploySettingsFileMissing -Exactly 1    
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
            Mock Test-IsPreviousDeploySettingsFileMissing { $false } 
            Mock Test-HaveDeploySettingsChangedSinceLastDeploy { $true }
            $settings = @{TargetServer = "."; TargetDatabaseName = "foo" }
   
            $result = Test-ShouldDeployDacpac -settings $settings -dacpacFile $dacpacPath -publishfile $publishFile 
                
            $result | Should -Be $true
            
            Should -Invoke Test-HaveDeploySettingsChangedSinceLastDeploy #-Exactly 1 #-Scope It
            Should -Invoke Test-IsPreviousDeploySettingsFileMissing #-Exactly 1 

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
    Context 'Test-ShouldDeployDacpac' {
                
        It "Given the deploy settings have changed, result Should -Be true" {
                
            $localsettings = "simon"
            Mock Test-HaveDeploySettingsChangedSinceLastDeploy -ParameterFilter { $Settings -eq $localsettings } { $true }

            Mock Test-IsPreviousDeploySettingsFileMissing { $false } 
            
            $result = Test-ShouldDeployDacpac -settings $localsettings -dacpacFile $dacpacPath -publishfile $publishFile 
                
            $result | Should -Be $true
    
            Assert-MockCalled Test-HaveDeploySettingsChangedSinceLastDeploy -Exactly 1 -Scope It
            Assert-MockCalled Test-IsPreviousDeploySettingsFileMissing -Exactly 1 -Scope It

        }
    }

    Context 'Invoke-scalar' {
        It 'should make connection to the server specified' {
            [string] $Server = "bob"
            [string] $DBName = "dbbob"
            [string] $User = "oddman"

            $pwd = ("insecure " | ConvertTo-SecureString -AsPlainText -Force)
            
            Mock Invoke-SqlScalarInternal
            Mock Close-SqlConnection
            Mock New-SqlConnection 

            Invoke-SqlScalar -TargetServer $Server -DatabaseName $DBName -TargetUser $User -TargetPasswordSecure $pwd -Query "select 1" 

            Assert-MockCalled New-SqlConnection -ParameterFilter { $TargetServer -eq $Server } -Exactly 1 
        }
    }

    
    Context 'settings file exists, settings not changed' {
       
        It "Given database not found, deployguard returns true" {

            Mock Test-IsPreviousDeploySettingsFileMissing { $false } 
            Mock Test-HaveDeploySettingsChangedSinceLastDeploy { $false }
            Mock Invoke-SqlScalar -ParameterFilter { $Query -like "Select top 1 name from sys.databases where name*" } {  }
    
            $settings = @{TargetServerName = "."; TargetDatabaseName = "dbdoesnotexist" }
            $result = Test-ShouldDeployDacpac -settings $settings -dacpacFile $dacpacPath -publishfile $publishFile -verbose
                
            $result | Should -Be $true
            Assert-MockCalled Invoke-SqlScalar -Exactly 1 -Scope It
        }
    }
    Context "test" {  
        It "Given database found deployguard returns true if no deployment table exists" {
            Mock Test-IsPreviousDeploySettingsFileMissing { $false } 
            Mock Test-HaveDeploySettingsChangedSinceLastDeploy { $false }
            Mock Invoke-SqlScalar -ParameterFilter { $Query -eq "Select top 1 DeploymentCreated from Deploy.Deployment order by DeploymentCreated Desc" } {}
    
            Mock Invoke-SqlScalar -ParameterFilter { $DatabaseName -eq 'master' -and $Query -like "Select top 1 name from sys.databases where name*" } { 'randomName1' }
            $settings = @{TargetServer = "."; TargetDatabaseName = "tabledoesnotexist" }    
            $result = Test-ShouldDeployDacpac  -settings $settings -dacpacFile $dacpacPath -publishfile $publishFile
                
            $result | Should -Be $true
            Assert-MockCalled Invoke-SqlScalar -Exactly 1 -Scope It
        }
    }
    Context "test2 " {
        It "Given database found deployguard returns false if deployment table exists with later date" {
            Mock Test-IsPreviousDeploySettingsFileMissing { $false } 
            Mock Test-HaveDeploySettingsChangedSinceLastDeploy { $false }
            Mock Invoke-SqlScalar -ParameterFilter { $DatabaseName -eq 'master' -and $Query -like "Select top 1 name from sys.databases where name*" } { 'randomName1' }
            Mock Invoke-SqlScalar -ParameterFilter { $DatabaseName -eq 'randomName1' -and $Query -eq "Select top 1 DeploymentCreated from Deploy.Deployment order by DeploymentCreated Desc" } { Get-Date -Year 2200 -Month 1 -Day 1 }
    
            $settings = @{TargetServer = "."; TargetDatabaseName = "randomName1" }    
                
            $result = Test-ShouldDeployDacpac  -settings $settings -dacpacFile $dacpacPath -publishfile $publishFile  
                
            $result | Should -Be $false
            Assert-MockCalled Invoke-SqlScalar -Exactly 2 -Scope It
        }
            
        It "Given database found and a previous old deployment deployguard returns true if dacpac is newer" {
            Mock Test-IsPreviousDeploySettingsFileMissing { $false } 
            Mock Test-HaveDeploySettingsChangedSinceLastDeploy { $false }
            Mock Invoke-SqlScalar -ParameterFilter { $DatabaseName -eq 'master' -and $Query -like "Select top 1 name from sys.databases where name*" } { 'randomName2' }
            Mock Invoke-SqlScalar -ParameterFilter { $DatabaseName -eq 'randomName2' -and $Query -eq "Select top 1 DeploymentCreated from Deploy.Deployment order by DeploymentCreated Desc" } { Get-Date -Year 1900 -Month 1 -Day 1 }
    
            $settings = @{TargetServer = "."; TargetDatabaseName = "randomName2" }    
    
            $result = Test-ShouldDeployDacpac  -settings $settings -dacpacFile $dacpacPath -publishfile $publishFile  
                
            $result | Should -Be $true
            Assert-MockCalled Invoke-SqlScalar -Exactly 2 -Scope It
        }        
    
    
    }
       
}

