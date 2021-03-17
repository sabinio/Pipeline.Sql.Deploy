param($ModulePath, $SourcePath, $ProjectName)

BeforeDiscovery {
	if (-not $PSBoundParameters.ContainsKey("ProjectName")) { $ProjectName = (get-item $PSScriptRoot).basename -replace ".tests", "" }
	if (-not $PSBoundParameters.ContainsKey("ModulePath")) { $ModulePath = "$PSScriptRoot\..\$ProjectName.module" }
	if (-not  $PSBoundParameters.ContainsKey("SourcePath")) { $SourcePath = "$ModulePath" }

	$CommandName = [IO.Path]::GetFileName($PSCommandPath).Replace(".Tests.ps1", "")
	
	$ModulePath = resolve-path $ModulePath
	$SourcePath = Resolve-path $SourcePath
	
	. "$ModulePath/Functions/$CommandName.ps1"
}
BeforeAll{
	Set-StrictMode -Version 1.0
}
Describe "Checking Previous Settings"  {
	
	It "Should get settings from database"{
		Test-IsPreviousDeploySettingsFileMissing 

    }

}
    
