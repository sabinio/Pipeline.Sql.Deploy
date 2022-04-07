function Get-DeploySettingsFromDB{
  [CmdletBinding()]
  [OutputType([Hashtable])]
  param($ServerName, $Database,$User, [SecureString]$PasswordSecure, $DacpacName)

 $sqlcmdparams = @{}
 if (-not [string]::IsNullOrWhiteSpace($user)){
  $sqlcmdparams.Credential = (New-Object System.Management.Automation.PSCredential $User, $PasswordSecure) 
 }
 $DeployRecord = Invoke-SqlCmd -Query "Select top 1 DeploymentCreated, DeployPropertiesJSON from Deploy.Deployment  where json_value(DeployPropertiesJSON,'$.Parameters.dacpacname') = '$DacpacName' order by DeploymentCreated Desc" `
  -Database $Database `
  -ServerInstance $ServerName `
  -MaxCharLength 32767 `
  @sqlcmdparams
  $DeployPropertiesObject = ($DeployRecord.DeployPropertiesJSON | convertfrom-json)

 return @{LastDeployDate = $DeployRecord.DeploymentCreated; SettingsToCheck=$DeployPropertiesObject.SettingsToCheck;Settings = $DeployPropertiesObject.Parameters;Hash=$DeployPropertiesObject.Hash }
}
