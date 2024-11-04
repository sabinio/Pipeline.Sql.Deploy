
param ( [string] $Tests
    ,$outputFolder 
    ,$where
    ,[string[]] $other
    ,$artifactsPath
    )

$nunitpath = $env:NunitConsolePath

$nunitArgs = @($Tests)
$nunitArgs += "--result=TestResult.xml;format=nunit2","--out=testoutput.log"

if ($outputFolder) {$nunitArgs += "--work=$outputFolder"}
if ($artifactsPath) {$nunitArgs += "--params=artifactsPath=$artifactsPath"}
if ($where) {$nunitArgs+=$where} #--where=test =~ AssertMergeScenario"
if ($other) {Write-Host "Adding otherparams to nunit Args"; $nunitArgs += $Other}




Write-Host $nunitpath ($nunitArgs -Join " ") -ForegroundColor White -BackgroundColor DarkGreen
&$nunitpath $nunitArgs # 2>&1

$res = [xml](Get-Content (join-path $outputFolder "TestResult.xml") -Raw)
$res.SelectSingleNode("/test-results/test-suite/results").SelectNodes(".//test-suite") | Format-Table
#if ($LASTEXITCODE -ne 0) {
#    $_.Exception
#}

