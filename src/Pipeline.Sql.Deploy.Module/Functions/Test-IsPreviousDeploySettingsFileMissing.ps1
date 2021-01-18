Function Test-IsPreviousDeploySettingsFileMissing {
    [CmdletBinding()]
    param (
        [string]$DBDeploySettingsFile
    )
        Write-Verbose "Test-IsPreviousDeploySettingsFileMissing" -Verbose
        return !(Test-Path $DBDeploySettingsFile)
    }