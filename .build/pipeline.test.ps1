[CmdletBinding()]
param($settings
    , $artifactsPath
    , $rootpath
    , $outPath )

    $ProjectName = $settings.ProjectName;

try {
        
    if (-not $noLogo) {
        Write-BannerTest
    }
    
    if (Test-Path "$outPath/test-results/") { $null }
    else {
        New-Item -ItemType Directory -Force -Path "$outPath/test-results/" | Out-Null 
    }
    get-module $ProjectName | remove-module  -force

	$container = New-PesterContainer -Path  "$rootpath/src/$ProjectName.Tests" -Data @{ModulePath="$artifactsPath\$ProjectName";ProjectName=$ProjectName}; #An empty data is required for Pester 5.1.0 Beta 
	$filters = @{}
	if ($settings.TestFilter -ne ""){
		$filters.Name =$settings.TestFilter
	}
	else {
		$filters.tag =  "PSScriptAnalyzer"
	}
	$ScriptAnalysis = Invoke-Pester -container $container -passthru @filters
	$ScriptAnalysis | Export-NUnitReport -path  "$outPath/test-results/$ProjectName.PsScripttests.results.xml" `
							
	
	$container = New-PesterContainer -Path "$rootpath/src/$ProjectName.Tests" -Data @{ModulePath="$artifactsPath\$ProjectName";ProjectName=$ProjectName}  #An empty data is required for Pester 5.1.0 Beta 

	$pesterpreference = [PesterCOnfiguration]::Default      
	$pesterpreference.CodeCoverage.Enabled=$true
	$pesterpreference.CodeCoverage.OutputPath  = "$outPath/test-results/coverage_$ProjectName.xml"  
	$pesterpreference.CodeCoverage.Path = "$artifactsPath\$ProjectName\Functions\*.ps1" 
    $pesterpreference.Run.Container = $container
    $pesterpreference.Run.PassThru = $true
    $pesterpreference.Filter.ExcludeTag =  "PSScriptAnalyzer" 
    $pesterpreference.Filter.FullName =  $settings.TestFilter 
    
    $NormalTests = Invoke-Pester -Configuration $pesterpreference 
	
	$NormalTests |Export-NUnitReport -path  "$outPath/test-results/$ProjectName.tests.results.xml" 
	$pesterpreference = [PesterCOnfiguration]::Default     
	
    Write-Host "Normal Tests Total $($NormalTests.TotalCount ) Passed $($NormalTests.PassedCount) Skipped $($NormalTests.NotRunCount)"
    Write-Host "ScriptAnalysis Tests Total $($ScriptAnalysis.TotalCount ) Passed $($ScriptAnalysis.PassedCount) Skipped $( $ScriptAnalysis.NotRunCount) "
    if ($settings.FailOnTests -eq $true -and `
        ($NormalTests.TotalCount -ne ($NormalTests.PassedCount + $NormalTests.NotRunCount)`
        -or $ScriptAnalysis.TotalCount -ne ($ScriptAnalysis.PassedCount+ $ScriptAnalysis.NotRunCount)  ))
        {
            Throw "Tests Failed see above"
    }
}

catch {
    throw
}
