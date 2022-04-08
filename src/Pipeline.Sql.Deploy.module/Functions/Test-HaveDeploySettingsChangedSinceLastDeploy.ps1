Function Test-HaveDeploySettingsChangedSinceLastDeploy {
    [CmdletBinding()]
    param (
        $OldSettings,
        $Settings
    )
    #Compares settings

    $OldSettingsJson = (Get-SettingsAsJson -settings $OldSettings )
    Write-Verbose "OldSettings  $($OldSettingsJson.Length)"
    Write-Verbose "$OldSettingsJson"
    $NewSettingsJson = (Get-SettingsAsJson -settings $Settings )
    Write-Verbose "NewSettings $($NewSettingsJson.Length)"
    Write-Verbose "$NewSettingsJson"
    for ($i = 0; $i -lt $NewSettingsJson.Length; $i++) {
        #ToDO show whats changed
    }
    return $OldSettingsJson -ne $NewSettingsJson
}