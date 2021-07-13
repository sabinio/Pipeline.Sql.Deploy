param($ModulePath, $SourcePath, $ProjectName)

BeforeDiscovery {


}
BeforeAll{
	if (-not (Test-Path variable:ProjectName)) { $ProjectName = (get-item $PSScriptRoot).basename -replace ".tests", "" }
	if (-not (Test-Path variable:ModulePath)) { $ModulePath = "$PSScriptRoot\..\$ProjectName.module" }
	if (-not  (Test-Path variable:SourcePath)) { $SourcePath = "$ModulePath" }

	$CommandName = [IO.Path]::GetFileName($PSCommandPath).Replace(".Tests.ps1", "")
	
	$ModulePath = resolve-path $ModulePath
	$SourcePath = Resolve-path $SourcePath
	
	get-module pipeline.sql.deploy | remove-module
	. "$ModulePath/Functions/$CommandName.ps1"

	Set-StrictMode -Version 1.0
}
Describe "Checking Previous Settings"  {
	
	It "Should return false if no path passed in"{
		Test-IsPreviousDeploySettingsFileMissing | should -be $false

    }
	It "Should return false if no path passed in"{
		Test-IsPreviousDeploySettingsFileMissing "somemissingfile.txt" | should -be $true

    }

}
    
