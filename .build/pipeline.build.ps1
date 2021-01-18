[CmdletBinding()]
param($rootPath, $Settings)

try {
	$ProjectName = $settings.ProjectName;

	push-location $rootPath
	if (-not $noLogo) {
		Write-BannerBuild
	}

	if ($settings.CleanBuild) {
		#   remove-item "src/$dbProjectName/bin/$($settings.buildconfig)/" -force -Recurse | Out-Null
	}
	$Functions = (Get-ChildItem $rootpath/src/$ProjectName.module/Functions -File | Select-Object ).BaseName

	Write-Host ([IO.Path]::Combine($rootpath, "src", "$ProjectName.module", "$ProjectName.psd1"))
	Test-ModuleManifest ([IO.Path]::Combine($rootpath, "src", "$ProjectName.module", "$ProjectName.psd1"))
	Update-ModuleManifest -Path ([IO.Path]::Combine($rootpath, "src", "$ProjectName.module", "$ProjectName.psd1"))   -FunctionsToExport $Functions
		
	$container = New-PesterContainer -Path "$rootpath/src/$ProjectName.ConfigTests";
	Write-Host ($Container | Format-List | out-string)

	$config = [PesterConfiguration]::Default
	$Config.Run.PassThru = $true
	$config.Run.Path = "$rootpath/src/$ProjectName.ConfigTests" 
	#	$config.Run.Container=@($container) 
	$config.Filter.Tag = "PSScriptAnalyzer"
	$config.Filter.ExcludeTag = "$($settings.ExcludeTags)"

	$results = Invoke-Pester -container $container -passthru -ExcludeTag "$($settings.ExcludeTags)" 
	$results | Export-NUnitReport -path  "$outPath/test-results/$ProjectName.configTests.results.xml" 
    
	if ($settings.FailOnTests -eq $true -and $results.TotalCount -ne ($results.PassedCount + $results.SkippedCount)) {
		throw "Tests have failed see results above"
	}    

	$container = New-PesterContainer -Path  "$rootpath/src/$ProjectName.Tests"  #An empty data is required for Pester 5.1.0 Beta 
	  
	$results = Invoke-Pester -container $container -passthru 	-Tag "ModuleInstall" 	
	$results | Export-NUnitReport -path "$outPath/test-results/$ProjectName.ModuleInstall.results.xml" 
}
catch {
	throw
}
finally {
	Pop-Location
}