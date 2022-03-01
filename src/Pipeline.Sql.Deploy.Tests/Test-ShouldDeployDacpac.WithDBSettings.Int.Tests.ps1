
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
    if (-not (test-path "Variable:configRoot") ) {$configRoot = "$PSScriptRoot\..\..\.build\config"}
    if (-not (test-path "Variable:environment") ) {$environment = "localdev"}
    write-Verbose "----$PSScriptRoot"-Verbose

    push-location "$PSScriptRoot\..\.."
    $settings = Get-ProjectSettings -environment $environment -ConfigRootPath $configRoot -Verbose:$VerbosePreference
    Write-Host ($settings | convertto-json)
}


Describe "Integration tests"{
    BeforeAll {
        $dacpacPath = "TestDrive:\test.dacpac"
        Set-Content $dacpacPath -value "testdacpac"
        $publishFile = "TestDrive:\publish.xml"
        Set-Content $publishFile -value "testdacpac" 
        $publishFile =  "TestDrive:\publish.xml"

        $dbDeployPath = "TestDrive:\deploy\"
        if (-not (Test-path $dbDeployPath)){new-item $dbDeployPath  -type directory | out-null}
        $dbDeployPath = (Get-Item $dbDeployPath).FullName
    }

    Context "DBDeploySettingsFile is not specified" {  
        It "Given database is deployed Test-ShouldDeployDacpac should retun $false" {
            $publish = $publishFile
            $DBSettings = [ordered]@{TargetServerName=$settings.serverName;
                TargetUser=$settings.sqlAdminLogin;
                TargetPasswordSecure=$Settings.SecurePassword;
                TargetDatabaseName="TestDB"
                Variables=@("/v:foo=bar")
                OutputDeployScript = $settings.OutputDeployScript;
                action="Publish";
                publishFile=$settings.publishFile
            }

            $dbExists = Invoke-sqlScalar -query "select count(1) from sys.databases where name = 'TestDB'"  -TargetServer $settings.serverName -Targetuser $settings.sqlAdminLogin -TargetPasswordSecure $settings.SecurePassword -DatabaseName "master" -verbose:$VerbosePreference
            
        #    if ($dbExists -eq 0){
            Invoke-DatabaseDacpacDeploy -dacpacFile $settings.dacpacPath `
            -sqlPackagePath $($env:SqlpackagePathExe) `
            @DBSettings `
            -scriptParentPath  $dbDeployPath `
            -TargetTimeout 10 `
            -CommandTimeout 30 `
            -Verbose:$VerbosePreference
        #    }
           # $dbExists = Invoke-sqlScalar -query "drop table if exists  deployment.deploy"  -TargetServer $settings.serverName -Targetuser $settings.sqlAdminLogin -TargetPasswordSecure $settings.SecurePassword -DatabaseName "master" -verbose:$VerbosePreference
            
            Test-ShouldDeployDacpac -settings $DBSettings -dacpacFile $settings.dacpacPath -Verbose  -publishFile $settings.publishFile | Should -be $false
        }
        It "Given database is deployed and a settings changed Test-ShouldDeployDacpac should retun $true" {
            $publish = $publishFile
            $DBSettings = [ordered]@{TargetServerName=$settings.serverName;
                TargetUser=$settings.sqlAdminLogin;
                TargetPasswordSecure=$Settings.SecurePassword;
                TargetDatabaseName="TestDB"
                Variables=@("/v:foo=bar")
                OutputDeployScript = $settings.OutputDeployScript;
                action="Publish";
                publishFile=$settings.publishFile
            }

            $dbExists = Invoke-sqlScalar -query "select count(1) from sys.databases where name = 'TestDB'"  -TargetServer $settings.serverName -Targetuser $settings.sqlAdminLogin -TargetPasswordSecure $settings.SecurePassword -DatabaseName "master" -verbose:$VerbosePreference
            
        #    if ($dbExists -eq 0){
            Invoke-DatabaseDacpacDeploy -dacpacFile $settings.dacpacPath `
            -sqlPackagePath $($env:SqlpackagePathExe) `
            @DBSettings `
            -scriptParentPath  $dbDeployPath `
            -TargetTimeout 10 `
            -CommandTimeout 30 `
            -Verbose:$VerbosePreference
        #    }
           # $dbExists = Invoke-sqlScalar -query "drop table if exists  deployment.deploy"  -TargetServer $settings.serverName -Targetuser $settings.sqlAdminLogin -TargetPasswordSecure $settings.SecurePassword -DatabaseName "master" -verbose:$VerbosePreference
            
           $DbSettings.Variables = @("/v:foo=bar2")
            Test-ShouldDeployDacpac -settings $DBSettings -dacpacFile $settings.dacpacPath -Verbose  -publishFile $settings.publishFile  | Should -be $true
        }

    }       
}

