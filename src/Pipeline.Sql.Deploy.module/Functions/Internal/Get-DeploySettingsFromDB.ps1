function Get-DeploySettingsFromDB{
  [CmdletBinding()]
  param($ServerName, $Database,$User, [SecureString]$PasswordSecure, $DacpacName)

 $sqlcmdparams = @{}
 if (-not [string]::IsNullOrWhiteSpace($user)){
  $sqlcmdparams.Credential = (New-Object System.Management.Automation.PSCredential $User, $PasswordSecure) 
 }
 $DeployRecord = Invoke-SqlCmd -Query "Select top 1 DeploymentCreated, DeployPropertiesJSON from Deploy.Deployment  where json_value(DeployPropertiesJSON,'$.Parameters.dacpacname') = '$DacpacName' order by DeploymentCreated Desc" `
  -Database $Database `
  -ServerInstance $ServerName `
  @sqlcmdparams
  
 return @{LastDeployDate = $DeployRecord.DeploymentCreated; Settings=$DeployRecord.DeployPropertiesJSON}
}
