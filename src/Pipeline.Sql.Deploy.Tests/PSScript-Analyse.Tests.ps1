param($ModulePath, $SourcePath, $ProjectName)
BeforeDiscovery {
	if (-not $PSBoundParameters.ContainsKey("ProjectName")) { $ProjectName = (get-item $PSScriptRoot).basename -replace ".tests", "" }
	if (-not $PSBoundParameters.ContainsKey("ModulePath")) { $ModulePath = "$PSScriptRoot\..\$ProjectName.module" }
	if (-not  $PSBoundParameters.ContainsKey("SourcePath")) { $SourcePath = "$ModulePath" }

	$ModulePath = resolve-path $ModulePath
	$SourcePath = Resolve-path $SourcePath
	$Modules = Get-ChildItem $ModulePath -Filter '*.psm1' -Recurse
	
	$Scripts = Get-ChildItem $ModulePath -Filter '*.ps1' -Recurse | Where-Object { $_.name -NotMatch 'Tests.ps1' }

	$ExcludeRules = @('PSAvoidTrailingWhitespace', 'PSAvoidUsingWriteHost' )
    
	$Rules = (Get-ScriptAnalyzerRule  | Where-Object { $ExcludeRules -notcontains $_.ruleName }).RuleName
}
BeforeAll {
	
	$ExcludeRules = @('PSAvoidTrailingWhitespace', 'PSAvoidUsingWriteHost' ,'PSUseOutputTypeCorrectly')
	if (-not $PSBoundParameters.ContainsKey("ProjectName")) { $ProjectName = (get-item $PSScriptRoot).basename -replace ".tests", "" }
	if (-not $PSBoundParameters.ContainsKey("ModulePath")) { $ModulePath = "$PSScriptRoot\..\$ProjectName.module" }
	if (-not  $PSBoundParameters.ContainsKey("SourcePath")) { $SourcePath = "$ModulePath" }
	$ModulePath = resolve-path $ModulePath
	$SourcePath = Resolve-path $SourcePath
}
Describe 'PSAnalyser Testing Modules ' -Tag "PSScriptAnalyzer" -ForEach $Modules {
	BeforeAll {
		$Module = $_
		$RuleResults = Invoke-ScriptAnalyzer -Path $module.FullName  -ExcludeRule $ExcludeRules
		$HasResults = $RuleResults.Count -ne 0
	} 
	It " Rule <_>" -TestCases $Rules {
		if ($HasResults) {
			($RuleResults | Where-Object { $_.Rulename -eq $rule }).Message | should -be $null Message "sdfsd"
                   
		}
	}

}
    

Describe 'PSAnalyser Testing scripts - <BaseName> <sourceFile>'  -Tag "PSScriptAnalyzer" -ForEach ($Scripts | ForEach-Object {@{Basename=$_.basename;sourcefile=$_.FullName}}) {
	BeforeAll {
		$sourceFile = $sourcefile.replace($ModulePath, $sourcePath )

		$RuleResults = Invoke-ScriptAnalyzer -Path $sourcefile    -ExcludeRule $ExcludeRules -Verbose
		$HasResults = $RuleResults.Count -ne 0
	}
	It "Rule <_> " -TestCases $Rules {
		$rule = $_
		if ($HasResults) {
			($RuleResults | Where-Object { $_.Rulename -eq $rule }).Message | should -be $null 
		}
	}
	
}

