function Get-SettingsAsJson{
    [CmdletBinding()]
    param ($settings)

    return ( $Settings | ConvertTo-Json -Compress)
}