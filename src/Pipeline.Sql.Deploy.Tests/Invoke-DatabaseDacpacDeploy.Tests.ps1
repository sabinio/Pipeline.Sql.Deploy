
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

        It "Returns list of scripts created" {
            mock invoke-command { $Global:LastExitCode=0 }
            $sqlpackagePath = "sqlpackage"
            $folder = [System.io.path]::Combine("TestDrive:", "ReturnValues", "out")
            if (test-path $folder) { remove-item $folder -Force -Recurse| out-null }
            $dacpac = [System.io.path]::Combine("TestDrive:", "dacpac", "test.dacpac")
            new-item  TestDrive:/dacpac -type directory -force | Out-Null
            copy-item $PSScriptRoot/Test.dacpac $dacpac -Force 
                
            $targetDatabase = "ReturnValues$($PsVersionTable.PsVersion)"
            $scripts = @("db.sql", "master.sql")
            $scripts | ForEach-Object { new-item -ItemType File ([System.io.path]::Combine($folder, $targetDatabase, $_)) -Force }

            $results = Invoke-DatabaseDacpacDeploy -dacpacfile $dacpac -sqlpackagePath $sqlpackagePath -action "script"  -scriptParentPath $folder -TargetServerName "." -TargetDatabaseName $targetDatabase -Variables @() -TargetTimeout 10 -CommandTimeout 100 -TargetIntegratedSecurity $true
                
            Assert-MockCalled invoke-command -Times 1 
            $results.Scripts.name | should -Be $scripts
        }

        It "When Dacpac is invalid" {
            $LASTEXITCODE=99
            mock invoke-command {  pwsh foo} #simmulating a command failure
            $sqlpackagePath = "sqlpackage"
            $folder = [System.io.path]::Combine("TestDrive:", "ReturnValues", "out")
            if (test-path $folder) { remove-item $folder -Force -Recurse| out-null }
            $dacpac = [System.io.path]::Combine("TestDrive:", "dacpac", "test.dacpac")
            new-item  TestDrive:/dacpac -type directory -force | Out-Null
            copy-item $PSScriptRoot/Test.dacpac $dacpac -Force 
        
            $targetDatabase = "InvalidDacPac$($PsVersionTable.PsVersion)" 
            $scripts = @("db.sql", "master.sql")
            $scripts | ForEach-Object { new-item -ItemType File ([System.io.path]::Combine($folder, $targetDatabase, $_)) -Force }
            $exception =$Null
            try{
                Invoke-DatabaseDacpacDeploy -dacpacfile $dacpac -sqlpackagePath $sqlpackagePath -action "script"  -scriptParentPath $folder -TargetServerName "." -TargetDatabaseName $targetDatabase -Variables @() -TargetTimeout 10 -CommandTimeout 100 -TargetIntegratedSecurity $true 
            } 
            catch {
                $exception = $_
            }
            $Exception.Exception.message | Should -belike  "SqlPackage returned non-zero exit code*"
        }

    }
}