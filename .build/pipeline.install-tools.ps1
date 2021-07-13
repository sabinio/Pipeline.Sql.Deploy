[CmdletBinding()]
param($ArtifactsPath)

function Repair-PSModulePath {

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
}

if (Get-PSRepository PowershellGalleryTest  -ErrorAction SilentlyContinue){Unregister-PSRepository PowershellGalleryTest}

$LatestVersion = "0.2.165" #This is just too slow (Find-Module Pipeline.Tools -Repository "PSGallery").Version
Write-Host "Getting Pipeline.Tools module $LatestVersion"

Repair-PSModulePath 

if (-not ((get-module Pipeline.Tools -ListAvailable).Version -eq $LatestVersion)) {
    Write-Host "Installing Pipeline.Tools module $LatestVersion"
    get-module Pipeline.Tools |remove-module
    Install-Module Pipeline.Tools -Scope CurrentUser -RequiredVersion $LatestVersion -Force -Repository PSGallery -Verbose:$VerbosePreference -SkipPublisherCheck -AllowClobber -ErrorAction "Stop"
}
if (-not ((get-module Pipeline.Tools -Verbose:$VerbosePreference).Version -eq $LatestVersion)){
    Write-Host "Importing Pipeline.Tools module  $LatestVersion"
    get-module Pipeline.Tools |remove-module
    Import-Module Pipeline.Tools -RequiredVersion $LatestVersion -Verbose:$VerbosePreference -ErrorAction "Stop"
}

#Powershell Get needs to be first otherwise it gets loaded by use of import-module
$modules = @{Module="PowerShellGet";Version=2.2.4.1},`
@{Module="Pipeline.Config";Version="0.2.10";Latest=$true;Repository="PSGallery"},`
@{Module="Pester";Version="5.1.1"},`
@{Module="PSScriptAnalyzer"},`
@{Module="platyps"}
$modules  |ForEach-Object{ Install-PsModuleFast @_ -Verbose:$VerbosePreference}

Write-Host "Modules loaded "
Write-Host (get-module $modules.module | Format-Table Name, Version,ModuleType, Path| Out-String)

Install-AzDoArtifactsCredProvider

