BeforeDiscovery{
    Write-Verbose "Module path Beforedisco - $ModulePath"-verbose
}
BeforeAll {
	Set-StrictMode -Version 1.0
    $CommandName = [IO.Path]::GetFileName($PSCommandPath).Replace(".Tests.ps1", "")
    if (-not (Test-path  Variable:\ProjectName)) { $ProjectName = (get-item $PSScriptRoot).basename -replace ".tests", "" }
    if (-not (Test-path  Variable:\ModulePath) -or "$ModulePath" -eq "") {$ModulePath = "$PSScriptRoot\..\$ProjectName.module" }

#    get-module $ProjectName | Remove-Module -Force
    . $ModulePath\Functions\Get-DacPacHash.ps1
    . $ModulePath\Functions\Internal\Get-DefaultSettingsToCheck.ps1
    . $ModulePath\Functions\Internal\$CommandName.ps1
}

Describe 'Get-DeployPropertiesHash' {
    It 'Should include the hash of the dacpacfile' {

        Mock Get-DacPacHash {"1234"}
        $DacpacFile = New-item "Testdrive:\Get-DeployPropertiesHash\test.dacpac" -ItemType File -Force

        $PropertiesHash = Get-DeployPropertiesHash -dacpacfile $DacpacFile
        Should -Invoke Get-DacPacHash -ParameterFilter {$DacpacFile} -Exactly 1

        $PropertiesHash.Hash | Should -be "1234"
    }
}
