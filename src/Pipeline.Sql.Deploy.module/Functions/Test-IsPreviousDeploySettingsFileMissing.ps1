Function Test-IsPreviousDeploySettingsFileMissing {
    [CmdletBinding()]
    param (
        [string]$DBDeploySettingsFile
    )
        Write-Verbose "Test-IsPreviousDeploySettingsFileMissing ($DBDeploySettingsFile)"
        if ([String]::IsNullOrEmpty($DBDeploySettingsFile)){
            return $false
        }
        return !(Test-Path $DBDeploySettingsFile)
    }