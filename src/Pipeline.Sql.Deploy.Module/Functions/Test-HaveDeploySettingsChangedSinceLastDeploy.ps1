Function Test-HaveDeploySettingsChangedSinceLastDeploy {
    [CmdletBinding()]
    param (
        [string] $DBDeploySettingsFile,
        $Settings
    )
    Write-Verbose "Checking $DBDeploySettingsFile"
    $OldSettings = (Get-Content $DBDeploySettingsFile -Raw).Trim()
    
    Write-Verbose "OldSettings  $($OldSettings.Length)"
    Write-Verbose $OldSettings

    $NewSettings = (Get-DbSettingsAsJson -settings $Settings )
    Write-Verbose "NewSettings $($NewSettings.Length)"
    Write-Verbose $NewSettings
    for ($i = 0; $i -lt $NewSettings.Length; $i++) {
        
    }
    return $OldSettings -ne $NewSettings
}