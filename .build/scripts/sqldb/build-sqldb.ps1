[CmdletBinding()]
Param(
    [string] $dbsolutionpath,
    [string] $config = "Debug",
    [string[]] $ExtraMSBuildSwitches
)
try {


    $msbuildArgs = @()
    $msbuildArgs += $ExtraMSBuildSwitches
    $msbuildArgs += "/p:Configuration=$config"
    $msbuildArgs += $dbsolutionpath

    &dotnet build $msbuildArgs  2>&1

    if ($LASTEXITCODE -ne 0) {
        Throw
    }
}
catch {
    throw
}