
BeforeAll {
    Set-StrictMode -Version 1.0
    $PSModuleAutoloadingPreference = "none"

    if (-not (Test-path  Variable:\ProjectName)) { $ProjectName = (get-item $PSScriptRoot).basename -replace ".tests", "" }
    $CommandName = [IO.Path]::GetFileName($PSCommandPath).Replace(".Tests.ps1", "")
    
    Get-Module $ProjectName | Remove-Module  

    if (-not (Test-path  Variable:\ModulePath) -or "$ModulePath" -eq "") { $ModulePath = "$PSScriptRoot\..\$ProjectName.module" }
  
    . $ModulePath\Functions\$CommandName.ps1
    . $ModulePath\Functions\Write-DbDeployParameterLog.ps1
    . $ModulePath\Functions\Get-DacPacHash.ps1
    . $ModulePath\Functions\Internal\Get-DeployPropertiesHash.ps1
    . $ModulePath\Functions\Internal\Get-DefaultSettingsToCheck.ps1
    . $ModulePath\Functions\Internal\Convert-ToSQLPackageSafeString.ps1
    . $ModulePath\Functions\Internal\Get-ModelChecksum.ps1
    . $ModulePath\Functions\Internal\Get-ReferencedDacpacsFromModel.ps1
    . $ModulePath\Functions\Internal\Add-ToList.ps1
    . $ModulePath\Functions\Internal\Get-EntraAccessToken.ps1
}

Describe 'Invoke-DatabaseDacpacDeploy' {
    BeforeAll {
        $PSModuleAutoloadingPreference = "none"
        $dacpacPath = "TestDrive:\test.dacpac"
        copy-item $PSScriptRoot\Test.dacpac $dacpacPath -Force
        $publishFile = "TestDrive:\publish.xml"
        Set-Content $publishFile -value "testdacpac" 
    }

    Context 'Return values' {
        BeforeAll {
            $folder = [System.io.path]::Combine("TestDrive:", "ReturnValues", "out")
            if (test-path $folder) { remove-item $folder -Force -Recurse | out-null }
            $dacpac = [System.io.path]::Combine("TestDrive:", "dacpac", "test.dacpac")
            $DacpacName = [io.path]::GetFileNameWithoutExtension($dacpacPath)

            $sqlpackagePath = "sqlpackage"
            new-item  TestDrive:/dacpac -type directory -force | Out-Null
            copy-item $PSScriptRoot/Test.dacpac $dacpac -Force 
            $BlankPassword = "BlankPassword" | ConvertTo-SecureString -asPlainText -Force

            mock invoke-command {  } #simmulating a command failure
            mock Get-DeployPropertiesHash { @{} }
            mock Add-ToList {  } #simmulating a command failure
        }
        BeforeEach{
            $Global:LASTEXITCODE = 0
        }
        It "Returns list of scripts created" {
                
            $targetDatabase = "ReturnValues$($PsVersionTable.PsVersion)"
            $scripts = @("db.sql", "master.sql")
            $scripts | ForEach-Object { new-item -ItemType File ([System.io.path]::Combine($folder, $targetDatabase, $_)) -Force }

            $results = Invoke-DatabaseDacpacDeploy -dacpacfile $dacpac -sqlpackagePath $sqlpackagePath -action "script"  -scriptParentPath $folder -TargetServerName "." -TargetDatabaseName $targetDatabase -Variables @() -TargetTimeout 10 -CommandTimeout 100 -TargetIntegratedSecurity $true
                
            Assert-MockCalled invoke-command -Times 1 
            $results.Scripts.name | should -Be $scripts
        }
        It "Outputs scripts if switch set" {
            mock write-host {}
            $targetDatabase = "ReturnValues$($PsVersionTable.PsVersion)"
            $scripts = @("db.sql", "master.sql")
            $scripts | ForEach-Object {
                $file = [System.io.path]::Combine($folder, $targetDatabase, $_)
                new-item -ItemType File $file -Force 
                set-content -path $file "some output script"
            }
            
            $results = Invoke-DatabaseDacpacDeploy  -OutputDeployScript -dacpacfile $dacpac -sqlpackagePath $sqlpackagePath -action "script"  -scriptParentPath $folder -TargetServerName "." -TargetDatabaseName $targetDatabase -Variables @() -TargetTimeout 10 -CommandTimeout 100 -TargetIntegratedSecurity $true
            Should -invoke -command "Write-Host" -ParameterFilter { $object -like "*DB Deploy Script*" } -exactly 2 
            Should -invoke -command "Write-Host" -ParameterFilter { $object -like "some output script" } -exactly 2
        }
        It "Masks Deploy Properties line from scripts" {
            mock write-host {}
            $targetDatabase = "ReturnValues$($PsVersionTable.PsVersion)"
            $scripts = @("db.sql", "master.sql")
            $scripts | ForEach-Object {
                $file = [System.io.path]::Combine($folder, $targetDatabase, $_)
                new-item -ItemType File $file -Force 
                set-content -path $file "DB Deploy`n:setvar DeployProperties Some really important secret"
            }
            $results = Invoke-DatabaseDacpacDeploy  -OutputDeployScript -dacpacfile $dacpac -sqlpackagePath $sqlpackagePath -action "script"  -scriptParentPath $folder -TargetServerName "." -TargetDatabaseName $targetDatabase -Variables @() -TargetTimeout 10 -CommandTimeout 100 -TargetIntegratedSecurity $true
            Should -invoke -command "Write-Host" -ParameterFilter { $object -like "*secret*" } -Times 0
        }

        It "When Dacpac is invalid" {
            $LASTEXITCODE = 99
            mock invoke-command { pwsh foo } #simmulating a command failure
        
            $targetDatabase = "InvalidDacPac$($PsVersionTable.PsVersion)" 
            $exception = $Null
            try {
                Invoke-DatabaseDacpacDeploy -dacpacfile $dacpac -sqlpackagePath $sqlpackagePath -action "script"  -scriptParentPath $folder -TargetServerName "." -TargetDatabaseName $targetDatabase -Variables @() -TargetTimeout 10 -CommandTimeout 100 -TargetIntegratedSecurity $true 
            } 
            catch {
                $exception = $_
            }
            $Exception.Exception.message | Should -belike  "SqlPackage returned non-zero exit code*"
        }
        It "Shoud use integrated security when user not passed in " {
            Invoke-DatabaseDacpacDeploy -dacpacfile $dacpac -sqlpackagePath $sqlpackagePath -action "script"  -scriptParentPath $folder -TargetServerName "." -TargetDatabaseName "SomeDatabase" -Variables @() -TargetTimeout 10 -CommandTimeout 100 -TargetIntegratedSecurity $true 
            Should -Invoke -CommandName "Add-ToList" -ParameterFilter { $item -like "*TargetUser*" } -Exactly 0 
        }
        
        It "Shoud use Targetuser When User passed in " {
            Invoke-DatabaseDacpacDeploy -dacpacfile $dacpac -sqlpackagePath $sqlpackagePath -action "script"  -scriptParentPath $folder -TargetServerName "." -TargetDatabaseName "SomeDatabase" -Variables @() -TargetTimeout 10 -CommandTimeout 100 -TargetUSer "TestUser" -TargetPasswordSecure $BlankPassword
            Should -Invoke -CommandName "Add-ToList" -ParameterFilter { $items | Where-Object { $_ -like "*TargetUser*TestUser*" } } -Exactly 1 
        }
        
        It "Shoud use Targetuser When User passed in " {
            Invoke-DatabaseDacpacDeploy -ServiceObjective "ReallyFast" -dacpacfile $dacpac -sqlpackagePath $sqlpackagePath -action "script"  -scriptParentPath $folder -TargetServerName "." -TargetDatabaseName "SomeDatabase" -Variables @() -TargetTimeout 10 -CommandTimeout 100 -TargetUSer "TestUser" -TargetPasswordSecure $BlankPassword
            Should -Invoke -CommandName "Add-ToList" -ParameterFilter { $item -like "*DatabaseServiceObjective*ReallyFast" } -Exactly 1 
        }
    
        It "Shoud use dacpac as prefix for scriptfiles nothing passed in" {
            Invoke-DatabaseDacpacDeploy -ServiceObjective "ReallyFast" -dacpacfile $dacpac -sqlpackagePath $sqlpackagePath -action "script"  -scriptParentPath $folder -TargetServerName "." -TargetDatabaseName "SomeDatabase" -Variables @() -TargetTimeout 10 -CommandTimeout 100 -TargetUSer "TestUser" -TargetPasswordSecure $BlankPassword
            Should -Invoke -CommandName "Add-ToList" -ParameterFilter { $item -like "*/DeployScriptPath:*$DacpacName`_db.sql" } -Exactly 1 
        }
        It "Shoud use dacpac as prefix for scriptfiles nothing passed in" {
            Invoke-DatabaseDacpacDeploy -DBScriptPrefix "foo" -ServiceObjective "ReallyFast" -dacpacfile $dacpac -sqlpackagePath $sqlpackagePath -action "script"  -scriptParentPath $folder -TargetServerName "." -TargetDatabaseName "SomeDatabase" -Variables @() -TargetTimeout 10 -CommandTimeout 100 -TargetUSer "TestUser" -TargetPasswordSecure $BlankPassword
            Should -Invoke -CommandName "Add-ToList" -ParameterFilter { $item -like "*/DeployScriptPath:*foo`_db.sql" } -Exactly 1 
        }
        It "Shoud use dacpac as prefix for scriptfiles nothing passed in" {
            Invoke-DatabaseDacpacDeploy -ServiceObjective "ReallyFast" -dacpacfile $dacpac -sqlpackagePath $sqlpackagePath -action "publish"  -scriptParentPath $folder -TargetServerName "." -TargetDatabaseName "SomeDatabase" -Variables @() -TargetTimeout 10 -CommandTimeout 100 -TargetUSer "TestUser" -TargetPasswordSecure $BlankPassword
            Should -Invoke -CommandName "Add-ToList" -ParameterFilter { $item -like "*/DeployScriptPath:*$DacpacName`_db.sql" } -Exactly 1 
        }
        It "Shoud use dacpac as prefix for scriptfiles nothing passed in" {
            Invoke-DatabaseDacpacDeploy -DBScriptPrefix "foo" -ServiceObjective "ReallyFast" -dacpacfile $dacpac -sqlpackagePath $sqlpackagePath -action "publish"  -scriptParentPath $folder -TargetServerName "." -TargetDatabaseName "SomeDatabase" -Variables @() -TargetTimeout 10 -CommandTimeout 100 -TargetUSer "TestUser" -TargetPasswordSecure $BlankPassword
            Should -Invoke -CommandName "Add-ToList" -ParameterFilter { $item -like "*/DeployScriptPath:*foo`_db.sql" } -Exactly 1 
        }
    }
    Describe "Debug messages" {
        BeforeAll {
            #Previsous Debug setting"
            $previousDebug = $env:SYSTEM_DEBUG
            $folder = [System.io.path]::Combine("TestDrive:", "ReturnValues", "out")
            if (test-path $folder) { remove-item $folder -Force -Recurse | out-null }
            $dacpac = [System.io.path]::Combine("TestDrive:", "dacpac", "test.dacpac")
            $sqlpackagePath = "sqlpackage"
            new-item  TestDrive:/dacpac -type directory -force | Out-Null
            copy-item $PSScriptRoot/Test.dacpac $dacpac -Force 
        }
        It "Should output parameters if env:SYSTEM_DEBUG is set" {
            $env:SYSTEM_DEBUG = "true"
            $Global:LASTEXITCODE = 0
            mock invoke-command {  } 
            mock Get-DeployPropertiesHash { @{} }

            $result = Invoke-DatabaseDacpacDeploy  -dacpacfile $dacpac -sqlpackagePath $sqlpackagePath -action "script"  -scriptParentPath $folder -TargetServerName "." -TargetDatabaseName "SomeDatabase" -Variables @() -TargetTimeout 10 -CommandTimeout 100 
        
            $result  | should -contain "/Action:script"
            $result -replace "[/\\]",""  | should -contain "SourceFile:TestDrive:dacpactest.dacpac"
            $result  | should -contain '/v:DeployProperties="{}"'
            $result  | should -contain "/TargetTimeout:10"
            $result  -replace "[/\\]","" | should -contain "DeployScriptPath:TestDrive:ReturnValuesoutSomeDatabasetest_db.sql"
            $result  | should -contain "/p:CommandTimeout=100"
            $result  | should -contain "/TargetServerName:."
            $result  | should -contain "/TargetDatabaseName:SomeDatabase"
            
        }
        It "Should not output access token" {
            $env:SYSTEM_DEBUG = "true"
            $Global:LASTEXITCODE = 0
            mock invoke-command {  } 
            mock Get-DeployPropertiesHash { @{} }
            mock write-host {}

            $result = Invoke-DatabaseDacpacDeploy  -dacpacfile $dacpac -sqlpackagePath $sqlpackagePath -action "script"  -scriptParentPath $folder -TargetServerName "." -AccessToken "fake_token_that_is_long" -TargetDatabaseName "SomeDatabase" -Variables @() -TargetTimeout 10 -CommandTimeout 100 
        
            should -Invoke -CommandName "write-host" -ParameterFilter { $object -like "*fake_token_that_is_long*" } -Exactly 0
        }
        It "Should allow for Drift Report"{
            $env:SYSTEM_DEBUG = "true"
            $Global:LASTEXITCODE = 0
            mock invoke-command {  } 
            mock Get-DeployPropertiesHash { @{} }

            $result = Invoke-DatabaseDacpacDeploy  -dacpacfile $dacpac -sqlpackagePath $sqlpackagePath -action "DriftReport"  -scriptParentPath $folder -TargetServerName "." -TargetDatabaseName "SomeDatabase" -PublishFile "foo.xml" -Variables @("/v:foo","/p:bob") -TargetTrustServerCert -TargetTimeout 10 -ServiceObjective p10 -CommandTimeout 100 
        
            $result  | should -contain "/Action:DriftReport"
            $result  -replace "[/\\]","" | should -contain "OutputPath:TestDrive:ReturnValuesoutSomeDatabasetest_drift.xml"
            $result | should  -not -belike "/SourceFile*"
            $result | should  -not -belike "/profile*"
            $result | should -not -BeLike "/v:*"
            $result | should -not -belike "/p:*"
            $result | should -contain "/TargetTrustServerCertificate:True"
            
            $result | should -contain "/TargetTimeout:10"
            $result | should -contain "/TargetServerName:."
            $result | should -contain "/TargetDatabaseName:SomeDatabase"
            
        }
        AfterAll {
            $env:SYSTEM_DEBUG = $previousDebug
        }
    }
    Describe "Invoke-DatabaseDacpacDeploy Parameter Checks" {
            BeforeAll {
                $folder = [System.io.path]::Combine("TestDrive:", "ReturnValues", "out")
                if (test-path $folder) { remove-item $folder -Force -Recurse | out-null }
                $dacpac = [System.io.path]::Combine("TestDrive:", "dacpac", "test.dacpac")
                $sqlpackagePath = "sqlpackage"
                new-item  TestDrive:/dacpac -type directory -force | Out-Null
                copy-item $PSScriptRoot/Test.dacpac $dacpac -Force 
                $env:SYSTEM_DEBUG = "true"
                $Global:LASTEXITCODE = 0
                mock invoke-command {  } 
                mock Get-DeployPropertiesHash { @{} }
            mock Add-ToList{}

        }
        It "Should use TargetTrustServerCert parameter for Script action"{
            $result = Invoke-DatabaseDacpacDeploy  -dacpacfile $dacpac -sqlpackagePath $sqlpackagePath -action "Script"  -scriptParentPath $folder -TargetServerName "." -TargetDatabaseName "SomeDatabase" -Variables @() -TargetTrustServerCert -TargetTimeout 10 -CommandTimeout 100 
      
            Should -Invoke -CommandName "Add-ToList" -ParameterFilter {$item -like "/TargetTrustServerCertificate:True"} -Exactly 1
        }
        It "Should NOT include TargetTrustServerCertificate when parameter not specified"{
            $result = Invoke-DatabaseDacpacDeploy  -dacpacfile $dacpac -sqlpackagePath $sqlpackagePath -action "Script"  -scriptParentPath $folder -TargetServerName "." -TargetDatabaseName "SomeDatabase" -Variables @() -TargetTimeout 10 -CommandTimeout 100 
            Should -Invoke -CommandName "Add-ToList" -ParameterFilter {$item -like "/TargetTrustServerCertificate:True"} -Exactly 0
        }

         It "Should include TargetConnectionString when parameter specified"{

            $result = Invoke-DatabaseDacpacDeploy  -dacpacfile $dacpac -sqlpackagePath $sqlpackagePath -action "Script"  -scriptParentPath $folder -TargetConnectionString "Server=.;Database=SomeDatabase;Trusted_Connection=True;" -Variables @() -TargetTimeout 10 -CommandTimeout 100 
                                                                                                          
            Should -Invoke -CommandName "Add-ToList" -ParameterFilter { $item -like "*TargetConnectionString*" } -Exactly 1 
            Should -Invoke -CommandName "Add-ToList" -ParameterFilter { $item -like "*TargetDatabase*" } -Exactly 0
            Should -Invoke -CommandName "Add-ToList" -ParameterFilter { $item -like "*TargetServer*" } -Exactly 0
        }

         It "Should include Accesstoken when parameter specified"{
            $result = Invoke-DatabaseDacpacDeploy  -dacpacfile $dacpac -sqlpackagePath $sqlpackagePath -action "Script"  -scriptParentPath $folder -AccessToken "sometoken much longer value" -TargetConnectionString "Server=.;Database=SomeDatabase;Trusted_Connection=True;" -Variables @() -TargetTimeout 10 -CommandTimeout 100 
                                                                                                          
            Should -Invoke -CommandName "Add-ToList" -ParameterFilter { $items -like "*AccessToken*" } -Exactly 1 
            Should -Invoke -CommandName "Add-ToList" -ParameterFilter { $item -like "*TargetUser*" -or $items -like "*TargetUser*" } -Exactly 0
            Should -Invoke -CommandName "Add-ToList" -ParameterFilter { $item -like "*TargetPassword*" -or $items -like "*TargetPassword*" } -Exactly 0
        }
         It "Should include AccesstokenSecure when parameter specified"{
            $secret = "some that is longer so we can give first and end bits" 
            $tokenSecure = ConvertTo-SecureString $secret -AsPlainText -Force
            $result = Invoke-DatabaseDacpacDeploy  -dacpacfile $dacpac -sqlpackagePath $sqlpackagePath -action "Script"  -scriptParentPath $folder -AccessTokenSecure $tokenSecure -TargetConnectionString "Server=.;Database=SomeDatabase;Trusted_Connection=True;" -Variables @() -TargetTimeout 10 -CommandTimeout 100 
                                                                                                          
            Should -Invoke -CommandName "Add-ToList" -ParameterFilter { $items -like "*AccessToken*" } -Exactly 1 
            Should -Invoke -CommandName "Add-ToList" -ParameterFilter { $items -like "*AccessToken*$secret" } -Exactly 1 
            Should -Invoke -CommandName "Add-ToList" -ParameterFilter { $item -like "*TargetUser*" -or $items -like "*TargetUser*" } -Exactly 0
            Should -Invoke -CommandName "Add-ToList" -ParameterFilter { $item -like "*TargetPassword*" -or $items -like "*TargetPassword*" } -Exactly 0
        }

         It "Should include clientid and clientsecret when parameter specified"{

            $secret = "some that is longer so we can give first and end bits" 
            mock Get-EntraAccessToken{ @{access_token=$secret} }
            $tokenSecure = ConvertTo-SecureString "sometoken" -AsPlainText -Force
            $foo = get-command Invoke-DatabaseDacpacDeploy | Select-Object -ExpandProperty parameters
            $result = Invoke-DatabaseDacpacDeploy  -dacpacfile $dacpac -sqlpackagePath $sqlpackagePath -action "Script"  -scriptParentPath $folder -TenantId "TenantId" -ClientId "someclient" -ClientSecret "somesecret" -TargetConnectionString "Server=.;Database=SomeDatabase;Trusted_Connection=True;" -Variables @() -TargetTimeout 10 -CommandTimeout 100 
                                                                                                          
            Should -Invoke -CommandName "Add-ToList" -ParameterFilter { $items -like "*AccessToken*" } -Exactly 1 
            Should -Invoke -CommandName "Add-ToList" -ParameterFilter { $items -like "*AccessToken*$secret" } -Exactly 1 
            Should -Invoke -CommandName "Add-ToList" -ParameterFilter { $item -like "*TargetUser*" -or $items -like "*TargetUser*" } -Exactly 0
            Should -Invoke -CommandName "Add-ToList" -ParameterFilter { $item -like "*TargetPassword*" -or $items -like "*TargetPassword*" } -Exactly 0
            Should -Invoke -CommandName "Get-EntraAccessToken" -ParameterFilter { $clientId -eq "someclient" -and $tenantId -eq "TenantId" -and $ClientSecret -eq "somesecret" } -Exactly 1
        }


         It "Should include clientid and clientsecret when parameter specified"{

            $secret = "some that is longer so we can give first and end bits" 
            mock Get-EntraAccessToken{ @{access_token=$secret} }
            $secretSecure = ConvertTo-SecureString "somelonger secret value" -AsPlainText -Force
            $foo = get-command Invoke-DatabaseDacpacDeploy | Select-Object -ExpandProperty parameters
            $result = Invoke-DatabaseDacpacDeploy  -dacpacfile $dacpac -sqlpackagePath $sqlpackagePath -action "Script"  -scriptParentPath $folder -TenantId "TenantId" -ClientId "someclient" -ClientSecretSecure $secretSecure -TargetConnectionString "Server=.;Database=SomeDatabase;Trusted_Connection=True;" -Variables @() -TargetTimeout 10 -CommandTimeout 100 
                                                                                                          
            Should -Invoke -CommandName "Add-ToList" -ParameterFilter { $items -like "*AccessToken*" } -Exactly 1 
            Should -Invoke -CommandName "Add-ToList" -ParameterFilter { $items -like "*AccessToken*$secret" } -Exactly 1 
            Should -Invoke -CommandName "Add-ToList" -ParameterFilter { $item -like "*TargetUser*" -or $items -like "*TargetUser*" } -Exactly 0
            Should -Invoke -CommandName "Add-ToList" -ParameterFilter { $item -like "*TargetPassword*" -or $items -like "*TargetPassword*" } -Exactly 0

            Should -Invoke -CommandName "Get-EntraAccessToken" -ParameterFilter { $clientId -eq "someclient" -and $tenantId -eq "TenantId" -and ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ClientSecretSecure))  -eq "somelonger secret value" )} -Exactly 1
        }

    }
    Describe "Should be able to get the failed script if sqlpackage fails" {
        BeforeAll {
            $targetDatabase = "nonexistentdb"

            $folder = [System.io.path]::Combine("TestDrive:", "ReturnValues", "out")
            if (test-path $folder) { remove-item $folder -Force -Recurse | out-null }
            new-item  (join-path $folder  $targetDatabase) -type directory -force | Out-Null
            

            $dacpac = [System.io.path]::Combine("TestDrive:", "dacpac", "test.dacpac")
            $sqlpackagePath = "sqlpackage"
            new-item  TestDrive:/dacpac -type directory -force | Out-Null
            copy-item $PSScriptRoot/Test.dacpac $dacpac -Force 

            mock invoke-command {
                dir "nonfile" 
            } #simmulating a command failure
        }
        It "Should return the failed script content" {
             

                 Set-Content "Some content" -Path "$folder\$targetDatabase\db.sql" -Force

                $outputs =  Invoke-DatabaseDacpacDeploy  -dacpacfile $dacpac -sqlpackagePath $sqlpackagePath -action "Script"  -scriptParentPath $folder -TargetServerName "." -TargetDatabaseName $targetDatabase -Variables @() -TargetTimeout 10 -CommandTimeout 100 -ErrorAction "Continue" -ErrorVariable err

                $outputs | should  -not -BeNullOrEmpty
                $outputs.Scripts | should -not -BeNullOrEmpty
                $outputs.Scripts[0].FullName| should -be (Get-Item "$folder\$targetDatabase\db.sql").FullName
                $outputs | should -not -BeNullOrEmpty
        }
    }
}