Function Test-IsPreviousDeploySettingsFileMissing {
    [CmdletBinding()]
    param (
        [string]$DBDeploySettingsFile
    )
        Write-Verbose "Test-IsPreviousDeploySettingsFileMissing" 
        return !(Test-Path $DBDeploySettingsFile)
    }