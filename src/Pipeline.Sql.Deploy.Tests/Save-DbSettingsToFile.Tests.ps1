param(
    $ModulePath,
    $ProjectName
)
BeforeDiscovery{
    Write-Verbose "Module path Beforedisco - $ModulePath"-verbose
}
BeforeAll {
	Set-StrictMode -Version 1.0
    $CommandName = [IO.Path]::GetFileName($PSCommandPath).Replace(".Tests.ps1", "")
    if (-not (Test-path  Variable:\ProjectName)) { $ProjectName = (get-item $PSScriptRoot).basename -replace ".tests", "" }
    if (-not (Test-path  Variable:\ModulePath) -or "$ModulePath" -eq "") {$ModulePath = "$PSScriptRoot\..\$ProjectName.module" }

    get-module $ProjectName | Remove-Module -Force
    . $ModulePath\Functions\$CommandName
    . $ModulePath\Functions\Internal\Get-SettingsAsJson.ps1
}

Describe 'Save-DbSettingsToFile' {
    It 'should create parent folder if not exists' {
        
        $Parent = [io.path]::Combine("TestDrive:","ParentFolder")
        $File = [io.path]::Combine($Parent,"Settings.file")
        if (test-path $Parent){Remove-item $Parent -Force -Recurse | out-null}

        Save-DbSettingsToFile -DBDeploySettingsFile $File -settings @{Server="localhost";Database="TestDB";User="TestUser";Password="TestPassword"}

        test-path $Parent | should -be $true
        Test-Path $file | should -be $true

    }
}
