function Get-DeploySettingsFromFile {
    [CmdletBinding()]
    param($DBDeploySettingsFile)

    Write-Verbose "Checking $DBDeploySettingsFile"
    return (Get-Content $DBDeploySettingsFile -Raw).Trim()
    
}