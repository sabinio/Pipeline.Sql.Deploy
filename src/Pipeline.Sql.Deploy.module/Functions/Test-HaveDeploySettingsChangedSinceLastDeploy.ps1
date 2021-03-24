Function Test-HaveDeploySettingsChangedSinceLastDeploy {
    [CmdletBinding()]
    param (
        $OldSettings,
        $Settings
    )
   
    $OldSettingsJson = (Get-DbSettingsAsJson -settings $OldSettings )
    Write-Verbose "OldSettings  $($NewSettingsJson.Length)"
    Write-Verbose $OldSettingsJson
    $NewSettingsJson = (Get-DbSettingsAsJson -settings $Settings )
    Write-Verbose "NewSettings $($NewSettingsJson.Length)"
    Write-Verbose $NewSettingsJson
    for ($i = 0; $i -lt $NewSettingsJson.Length; $i++) {
        
    }
    return $OldSettingsJson -ne $NewSettingsJson
}