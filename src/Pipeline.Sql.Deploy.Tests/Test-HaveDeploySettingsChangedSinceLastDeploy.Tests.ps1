param($ModulePath, $SourcePath, $ProjectName)


BeforeAll{
	if (-not (Test-Path variable:ProjectName)) { $ProjectName = (get-item $PSScriptRoot).basename -replace ".tests", "" }
	if (-not (Test-Path variable:ModulePath)) { $ModulePath = "$PSScriptRoot\..\$ProjectName.module" }
	if (-not  (Test-Path variable:SourcePath)) { $SourcePath = "$ModulePath" }

	$CommandName = [IO.Path]::GetFileName($PSCommandPath).Replace(".Tests.ps1", "")
	
	$ModulePath = resolve-path $ModulePath
	$SourcePath = Resolve-path $SourcePath
	
	get-module pipeline.sql.deploy | remove-module
	. "$ModulePath/Functions/$CommandName.ps1"
	. "$ModulePath/Functions/Internal/Get-DeploySettingsFromFile.ps1"
	. "$ModulePath/Functions/Save-DbSettingsToFile.ps1"
	. "$ModulePath/Functions/Internal/Get-SettingsAsJson.ps1"
	
	Set-StrictMode -Version 1.0
	$env:PSModulePath =""
}
Describe "Checking Previous Settings"  {
	It "Should return false if no path passed in"{
		$settings = @{Server="foo";database="bob"}
		$DBDeploySettingsFile = "TestDrive:\CompareSettings.settings"
		Save-DbSettingsToFile -Settings $settings -DBDeploySettingsFile $DBDeploySettingsFile -verbose

		Test-HaveDeploySettingsChangedSinceLastDeploy -OldSettings (Get-DeploySettingsFromFile -DBDeploySettingsFile $DBDeploySettingsFile ) -Settings $Settings | Should -be $false
		
    }


}
    
