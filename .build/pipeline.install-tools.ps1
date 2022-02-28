[CmdletBinding()]
param($ArtifactsPath)
try{
function Repair-PSModulePath {
    Write-host "Repair PSMOdulePath"
    if ($PSVersionTable.PsEdition -eq "Core") {
        $mydocsPath = join-path ([System.Environment]::GetFolderPath("MyDocuments")) "PowerShell/Modules"
    }
    else {
        $mydocsPath = join-path ([System.Environment]::GetFolderPath("MyDocuments")) "WindowsPowerShell/Modules"
    }

    If ("$($env:PSModulePath)".Split([IO.Path]::PathSeparator) -notcontains $mydocsPath) {
        Write-Verbose "Adding LocalModule folder to PSModulePath"
        $env:PSModulePath = "$mydocsPath$([IO.Path]::PathSeparator)$($env:PSModulePath)"
    }
    Write-host "Repair PSMOdulePath - End"
}

$ToolsPath = $ArtifactsPath

#$DebugPreference="continue"
Register-PackageSource -Location https://www.powershellgallery.com/api/v2 -providerName NUget -name NugetPS -Force -Verbose:$VerbosePreference -SkipValidate -Trusted

#if ((Get-PSRepository -Name PSGallery -Verbose:$VerbosePreference).InstallationPolicy -ne "Trusted"){set-psrepository -name PSGallery -InstallationPolicy Trusted -Verbose:$VerbosePreference}

if (Get-PSRepository PowershellGalleryTest -Verbose:$VerbosePreference -ErrorAction SilentlyContinue){
    Write-Host "Removing PSGalleryTest repository"
    Unregister-PSRepository PowershellGalleryTest
    }

$LatestVersion = "0.2.180" #This is just too slow (Find-Module Pipeline.Tools -Repository "PSGallery").Version
Write-Host "Getting Pipeline.Tools module $LatestVersion"

Repair-PSModulePath 

if (-not ((get-module Pipeline.Tools -ListAvailable -Verbose:$VerbosePreference).Version -ge $LatestVersion)) {
    Write-Host "Installing Pipeline.Tools module $LatestVersion"
    get-module Pipeline.Tools -Verbose:$VerbosePreference |remove-module -Verbose:$VerbosePreference
    Install-Module Pipeline.Tools -Scope CurrentUser -RequiredVersion $LatestVersion  -Verbose:$VerbosePreference -SkipPublisherCheck -AllowClobber -ErrorAction "Stop" -Force
}
if (-not ((get-module Pipeline.Tools -Verbose:$VerbosePreference).Version -ge $LatestVersion)){
    Write-Host "Importing Pipeline.Tools module  $LatestVersion"
    get-module Pipeline.Tools |remove-module
    Import-Module Pipeline.Tools -RequiredVersion $LatestVersion -Verbose:$VerbosePreference -ErrorAction "Stop"
}

#Powershell Get needs to be first otherwise it gets loaded by use of import-module
$modulefile = "$psscriptroot\modules.ps1"
$modules =  Invoke-Expression (Get-Content $modulefile -raw ) 
$moduleLock=@{}
$needNewLock =$false
if (test-path  "$modulefile.lock" ){
    $moduleLock = Invoke-Expression  (get-content "$modulefile.lock" -raw)
}
foreach ($module in $modules  ){
    $lockVersion = ($moduleLock | where-object {$_.Module -eq $module.Module}).Version
    if ($null -ne $lockVersion){
        Write-Host ("Locking module {0,-20} to {1,10}" -f $module.Module ,$lockVersion )
        $module.Version = $lockVersion
    }
    else{
        $needNewLock = $true
    }
}
$modules | ForEach-Object{ 	Install-PsModuleFast @_  -verbose:$VerbosePreference}

Write-Host "Modules loaded "
Write-Host (get-module $modules.module | Format-Table Name, Version,ModuleType, Path| Out-String)
if ($needNewLock) {
   Write-Host "Saving lock file"
   (get-module $modules.module | ForEach-Object{ "@{Module=`"$($_.Name)`";Version=`"$($_.Version)`"}" }) -Join ",`n" | out-file -encoding utf8 "$modulefile.lock"}

Install-AzDoArtifactsCredProvider

Write-verbose "Downloading sqlpackage"
# if (-not ( Test-path "$PackagePath\sqlpackage")){ New-Item -ItemType Directory -Path "$PackagePath\sqlpackage"  |Out-Null}

if ($PSVersionTable.Platform -eq "Unix"){
    $url = "https://go.microsoft.com/fwlink/?linkid=2185670"
    $sqlpackageExeName = "sqlpackage"
}
else{
    $sqlpackageExeName = "sqlpackage.exe"
    $url = "https://go.microsoft.com/fwlink/?linkid=2185669"
}

Install-ToolFromUrl -ToolPath "$ToolsPath\sqlpackage" -url $url;

$env:sqlPackagePath = resolve-path "$ToolsPath\sqlpackage"
$env:SqlpackagePathExe = join-path $env:sqlPackagePath $sqlpackageExeName
Write-Host "sqlpackage installed"

push-location $ToolsPath
    try{
    Install-Nuget ([IO.Path]::Combine($ToolsPath, "Nuget", "nuget.exe")) -Verbose:$VerbosePreference

    &$env:Nuget sources list| Where-Object {$_ -like "*powershellGallerytest*"} | ForEach-Object{&$env:Nuget sources remove -name powershellgallerytest}

    @{package = "Microsoft.SqlServer.DacFx"; subpath = "\lib\netstandard2.1"; ;env="NETCoreTargetsPath";nugetextraparams="-DependencyVersion","Ignore"} `
    , @{package = "Microsoft.Data.SqlClient"; subpath = "\runtimes\win\lib\netcoreapp2.1"; version="3.0.1"; env="SqlClient" ;nugetextraparams="-DependencyVersion","Ignore"} `
    , @{package = "sabinio.Sql.System.Dacpacs"; env="SystemDacPacs" ;nugetextraparams="-DependencyVersion","Ignore"} `
    , @{package = "System.ComponentModel.Composition"; subpath = "\lib\netcoreapp2.0";version="5.0.0"; env="ComponentModel" ;nugetextraparams="-DependencyVersion","Ignore"} `
    , @{package = "System.IO.Packaging"; subpath = "\lib\netstandard2.0"; ;version="5.0.0";env="SystemIOPackaging" ;nugetextraparams="-DependencyVersion","Ignore"} `
  | ForEach-Object { Install-ToolsPackageFromNuget -PackagePath . -Verbose:$VerbosePreference @_}

  $env:NETCoreTargetsPath = resolve-path $env:NETCoreTargetsPath
  
  $env:SqlClient = Resolve-Path $env:SqlClient
  if ((copy-item (join-path $env:ComponentModel "*.dll")   $env:NETCoreTargetsPath -PassThru).Count -ne 1) {Throw "Failed to copy 1 file from $($env:ComponentModel)" }
  if ((copy-item (join-path $env:SystemIOPackaging "*.dll")   $env:NETCoreTargetsPath -PassThru).Count -ne 1) {Throw "Failed to copy 1 file from $($env:SystemIOPackaging)" }
  if ((Copy-Item (join-path $env:SqlClient "*.dll")     $env:NETCoreTargetsPath -PassThru).Count -ne 1) {Throw "Failed to copy 1 file from $($env:SqlClient)" }
  if ((Copy-Item (join-path $env:SystemDacPacs "*")  $env:NETCoreTargetsPath -Recurse -PassThru -Force).Count -eq 0) {Throw "Failed to copy files from $($env:SystemDacPacs)" }


   <# @{package = "Microsoft.Build.Sql"; subpath = "\tools\netstandard2.1"; version = "0.1.1-alpha";env="MicrosoftBuildSqlRoot";nugetextraparams="-DependencyVersion","Ignore"} `
    , @{package = "sabinio.Sql.System.Dacpacs"; env="SystemDacPacs" ;nugetextraparams="-DependencyVersion","Ignore"} `
    | ForEach-Object { Install-ToolsPackageFromNuget -PackagePath . -Verbose:$VerbosePreference @_}

    $env:NETCoreTargetsPath = resolve-path ( [IO.Path]::Combine($env:MicrosoftBuildSqlRoot,"tools","netstandard2.1"))

    if ((Copy-Item (join-path $env:SystemDacPacs "*")  $env:NETCoreTargetsPath -Recurse -PassThru -Force).Count -eq 0) {Throw "Failed to copy files from $($env:SystemDacPacs)" }

    if ((Copy-Item (join-path $env:SystemDacPacs "*")  $env:NETCoreTargetsPath -Recurse -PassThru -Force).Count -eq 0) {Throw "Failed to copy files from $($env:SystemDacPacs)" }
    #>
}
finally {
    Pop-Location
}

<#
if ($PSVersionTable.Platform -eq "Unix"){
    $Env:VSPath = "/mnt/c/program files/microsoft visual studio"
}else{
    $Env:VSPath= (Get-VSSetupInstance | Sort-Object -Property InstallationVersion -Descending | Select-Object -First 1).InstallationPath 
}
$Env:MsbuildPath = (Get-ChildItem $Env:VSPath msbuild.exe -Recurse | select-object -First 1).FullName
Write-Host "Setting MsBuildPath to $($Env:MsbuildPath)"
#>

}
catch{
    throw
}