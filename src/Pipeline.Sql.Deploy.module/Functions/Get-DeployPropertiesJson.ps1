Function Get-DeployPropertiesJson{
    [CmdletBinding()]
    param(
        [string] $action, 
        [string] $TargetServerName, 
        [string] $TargetDatabaseName, 
        [string] $TargetUser, 
        [securestring] $TargetPasswordSecure, 
        [string] $TargetIntegratedSecurity,
        [string] $ServiceObjective,
        [string] $PublishFile,
        [string[]] $Variables,
        [string] $TargetTimeout,
        [string] $dacpacfile
    )

    $EnvironmentValues = @{}
    
    Get-ChildItem Env: | Where-Object Name -ne "Path" | ForEach-Object {
        $EnvironmentValues.($_.Name) = $_.Value
    }

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
    };    
    
    $Settings = @{Parameters = $ParamValues; EnvironmentValues = $EnvironmentValues}
    
    return (ConvertTo-Json $Settings -Compress).Replace('"', '@@') -replace "([a-z])\\\\""", "`$1\\\\`"" -replace "\[","&^" -replace "\]","`$"    
}