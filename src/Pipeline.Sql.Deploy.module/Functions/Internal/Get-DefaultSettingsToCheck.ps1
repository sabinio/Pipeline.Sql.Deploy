Function Get-DefaultSettingsToCheck{
    [CmdletBinding()]
    param(
        [string] $action, 
        [string] $TargetServerName, 
        [string] $TargetDatabaseName, 
      #  $TargetUser, 
       # [securestring] $TargetPasswordSecure, 
     #   $TargetIntegratedSecurity,
        $ServiceObjective,
        [string] $PublishFile,
        [string[]] $Variables,
   #     [string] $TargetTimeout,
   #     [string] $dacpacfile,
        [string] $dacpacname = (get-item $dacpacfile).basename,
        [parameter(ValueFromRemainingArguments = $true)]
        $extras
    )
    
    if ($extras){}
    return  @{action          = $action
            TargetServerName         = $TargetServerName
            TargetDatabaseName       = $TargetDatabaseName
            ServiceObjective         = $ServiceObjective
            PublishFile              = $PublishFile
            Variables                = $Variables
            dacpacname               = $dacpacname
}
};    