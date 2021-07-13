Function Test-HaveDeploySettingsChangedSinceLastDeploy {
    [CmdletBinding()]
    param (
        $OldSettings,
        $Settings
    )
    #Compares settings

    $OldSettingsJson = (Get-DbSettingsAsJson -settings $OldSettings )
    Write-Verbose "OldSettings  $($NewSettingsJson.Length)"
    Write-Verbose $OldSettingsJson
    $NewSettingsJson = (Get-DbSettingsAsJson -settings $Settings )
    Write-Verbose "NewSettings $($NewSettingsJson.Length)"
    Write-Verbose $NewSettingsJson
    for ($i = 0; $i -lt $NewSettingsJson.Length; $i++) {
        #ToDO show whats changed
    }
    return $OldSettingsJson -ne $NewSettingsJson
}