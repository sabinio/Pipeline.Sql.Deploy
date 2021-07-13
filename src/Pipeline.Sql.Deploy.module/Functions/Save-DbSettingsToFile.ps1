function Save-DbSettingsToFile{
    [CmdletBinding()]
    param (
        $settings,
        [string]$DBDeploySettingsFile
    )

    Write-Verbose "Saving DB deployment settings to $DBDeploySettingsFile"

    New-Item -ItemType Directory (Split-Path -Parent $DBDeploySettingsFile) -Force | Out-Null
    Get-SettingsAsJson $settings | Out-File $DBDeploySettingsFile -Force
}