param($ModulePath, $SourcePath, $ProjectName)

BeforeDiscovery {
	if (-not (Test-path "Variable:ProjectName")) { $ProjectName = (get-item $PSScriptRoot).basename -replace ".tests", "" }
	if (-not (Test-path "Variable:ModulePath")) { $ModulePath = "$PSScriptRoot\..\$ProjectName.module" }
	if (-not  (Test-path "Variable:SourcePath") -or [string]::IsNullOrWhiteSpace($sourcePath)) { $SourcePath = "$ModulePath" }

	Write-Verbose "ModulePath = $ModulePath" -Verbose
	Write-Verbose "SourcePath = $SourcePath" -Verbose
	$ModulePath = resolve-path $ModulePath

	$Modules = Get-ChildItem $ModulePath -Filter '*.psm1' -Recurse
	
	$Scripts = (Get-ChildItem $ModulePath -Filter '*.ps1' -Recurse | Where-Object { $_.name -NotMatch 'Tests.ps1' } ).FullName

}
BeforeAll{
	Set-StrictMode -Version 1.0
}
Describe 'Ensuring module and script files dont have bad characters' -Tag "PSScriptAnalyzer"  {
	
	It "<_>" -TestCases $Scripts  {
		$by =  [System.IO.File]::ReadAllBytes($_)
		$l=0;$c=0;
		$BadChars = (0..$by.length)|ForEach-Object{
			$i=$_
			if ($by[$i] -eq 0x0d){
				$l++;$c=0
			}
			else{
				$c++;
				if ($by[$i] -gt 0x7f )
				{
					[PSCustomObject]@{line=$l;column=$c;character=$i}
				}
			}
		}
		
		$BadChars | Should -Be @()
	
    }

}
    
