[CmdletBinding()]
Param(
    [string] $dbsolutionpath,
    [string] $config = "Debug",
    [string[]] $ExtraMSBuildSwitches,
    [string] $Msbuild  ,
    [string] $nugetPath 
)
try {
    Write-Verbose "nuget restore for $dbsolutionpath"

    &$nugetPath restore $dbsolutionpath


    Write-Verbose "Running MsBuild from $Msbuild"

    $msbuildArgs = @()
    $msbuildArgs += $ExtraMSBuildSwitches
    $msbuildArgs += "/p:Configuration=$config"
    $msbuildArgs += $dbsolutionpath

    & $msbuild $msbuildArgs  2>&1

    if ($LASTEXITCODE -ne 0) {
        Throw
    }
}
catch {
    throw
}