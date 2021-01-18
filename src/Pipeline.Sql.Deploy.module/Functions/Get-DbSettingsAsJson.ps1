function Get-DbSettingsAsJson{
    [CmdletBinding()]
    param ($settings)

    return ( $Settings | ConvertTo-Json -Compress)
}