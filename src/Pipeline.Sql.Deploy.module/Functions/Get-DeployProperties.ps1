Function Get-DeployProperties{
    [CmdletBinding()]
    param(
        [string] $action, 
        [string] $TargetServerName, 
        [string] $TargetDatabaseName, 
        [string] $TargetUser, 
        [securestring] $TargetPasswordSecure, 
        [string] $TargetIntegratedSecurity,
        $ServiceObjective,
        [string] $PublishFile,
        [string[]] $Variables,
        [string] $TargetTimeout,
        [string] $dacpacfile,
        [string] $dacpacname = (get-item $dacpacfile).basename,
        [hashtable] $SettingsToCheck,
        [parameter(ValueFromRemainingArguments = $true)]
        $extras
    )

    $EnvironmentValues = @{}
    
  #  Get-ChildItem Env: | Where-Object Name -ne "Path" | ForEach-Object {
  #      $EnvironmentValues.($_.Name) = $_.Value
  #   }
    if ($null -eq $extras){}

    $ParamValues = @{action          = $action
            TargetServerName         = $TargetServerName
            TargetDatabaseName       = $TargetDatabaseName
            TargetUser               = $TargetUser
            TargetPasswordSecure     = $TargetPasswordSecure
            TargetIntegratedSecurity = $TargetIntegratedSecurity
            ServiceObjective         = $ServiceObjective
            PublishFile              = $PublishFile
            Variables                = $Variables
            TargetTimeout            = $TargetTimeout
            dacpacfile               = $dacpacfile
            dacpacname               = $dacpacname
    };    
    if ($null -eq $SettingsToCheck){
      $SettingsToCheck = Get-DefaultSettingsToCheck @ParamValues
    }
    write-host "some text"
    write-host "some text"
    write-host "$psscriptroot"

    $Settings = @{Parameters = $ParamValues;SettingsToCheck=$SettingsToCheck; EnvironmentValues = $EnvironmentValues}
    
    return $Settings
}