param(
    [parameter(Mandatory = $false)] $serverName,
    $ModulePath,
    $ProjectName
)
BeforeDiscovery{

}
BeforeAll {
    Set-StrictMode -Version 1.0
    $PSModuleAutoloadingPreference = "none"

    if (-not (Test-path  Variable:\ProjectName)) { $ProjectName = (get-item $PSScriptRoot).basename -replace ".tests", "" }
    $CommandName = [IO.Path]::GetFileName($PSCommandPath).Replace(".Tests.ps1", "")
    
    Get-Module $ProjectName | Remove-Module  

    if (-not (Test-path  Variable:\ModulePath) -or "$ModulePath" -eq "") {$ModulePath = "$PSScriptRoot\..\$ProjectName.module" }
  
    . $ModulePath\Functions\$CommandName.ps1
    . $ModulePath\Functions\Write-DbDeployParameterLog.ps1
    . $ModulePath\Functions\Get-DeployPropertiesJson.ps1
    
}
Describe 'Invoke-DatabaseDacpacDeploy' {
    BeforeAll {
        $PSModuleAutoloadingPreference = "none"
        $dacpacPath = "TestDrive:\test.dacpac"
        Set-Content $dacpacPath -value "testdacpac"
        $publishFile = "TestDrive:\publish.xml"
        Set-Content $publishFile -value "testdacpac" 
    }

    Context 'Return values' {

        It "Returns list of scripts created" {
                mock invoke-command {0}
                $sqlpackagePath = "sqlpackage"
                $folder = [System.io.path]::Combine("TestDrive:","ReturnValues","out")
                if (test-path $folder){remove-item $folder -Force |out-null}
                $dacpac = [System.io.path]::Combine("TestDrive:","dacpac","test.dacpac")
                new-item $dacpac -force -type file | out-null
                
                $targetDatabase = "ReturnValues"
                $scripts = @("db.sql","master.sql")
                $scripts | ForEach-Object{new-item -ItemType File ([System.io.path]::Combine($folder,$targetDatabase,$_)) -Force}

                $results = Invoke-DatabaseDacpacDeploy -dacpacfile $dacpac -sqlpackagePath $sqlpackagePath -action "script"  -scriptParentPath $folder -TargetServerName "." -TargetDatabaseName $targetDatabase -Variables @() -TargetTimeout 10 -CommandTimeout 100 -TargetIntegratedSecurity $true
                
                Assert-MockCalled invoke-command -Times 1 
                $results.Scripts.name | should -Be $scripts
        }
    }
}