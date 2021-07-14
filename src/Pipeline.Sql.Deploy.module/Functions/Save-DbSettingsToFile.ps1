function Save-DbSettingsToFile{
    [CmdletBinding()]
    param (
        $settings,
        [string]$DBDeploySettingsFile
    )

    Write-Verbose "Saving DB deployment settings to $DBDeploySettingsFile"
    
    $parentFolder = Split-Path -Parent $DBDeploySettingsFile

    if (-not (Test-Path $parentFolder)){ New-Item -ItemType Directory $parentFolder -Force | Out-Null}

    Get-SettingsAsJson $settings | Out-File $DBDeploySettingsFile -Force
}