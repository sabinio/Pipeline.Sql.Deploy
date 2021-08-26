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
#$DebugPreference="continue"
Register-PackageSource -Location https://www.powershellgallery.com/api/v2 -providerName NUget -name NugetPS -Force -Verbose:$VerbosePreference -SkipValidate -Trusted

#if ((Get-PSRepository -Name PSGallery -Verbose:$VerbosePreference).InstallationPolicy -ne "Trusted"){set-psrepository -name PSGallery -InstallationPolicy Trusted -Verbose:$VerbosePreference}

if (Get-PSRepository PowershellGalleryTest -Verbose:$VerbosePreference -ErrorAction SilentlyContinue){Unregister-PSRepository PowershellGalleryTest}

$LatestVersion = "0.2.170" #This is just too slow (Find-Module Pipeline.Tools -Repository "PSGallery").Version
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
    $lockVersion = $moduleLock | where-object {$_.Module -eq $module.Module} | select-object -ExpandProperty Version
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
}
catch{
    throw
}