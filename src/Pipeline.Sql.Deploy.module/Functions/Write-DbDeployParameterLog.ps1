Function Write-DbDeployParameterLog {
    [CmdletBinding()]
    param(
        [string] $dacpacfile,
        [string] $action,
        [string] $TargetServerName,
        [string] $TargetDatabaseName,
        [string] $TargetIntegratedSecurity,
        [string] $ServiceObjective,
        [string] $PublishFile,
        [string[]] $Variables,
        [string] $TargetTimeout,
        [string] $CommandTimeout,
        [string] $sqlpackagePath,
        [string] $Username
    )

    Write-host "Deploying database to server" 
    Write-host "DacpacFile               : $dacpacfile" 
    Write-host "Action                   : $action" 
    Write-host "TargetServerName         : $TargetServerName" 
    Write-host "TargetDatabaseName       : $TargetDatabaseName" 
    Write-host "TargetIntegratedSecurity : $TargetIntegratedSecurity" 
    Write-host "ServiceObjective         : $ServiceObjective"
    Write-host "Profile                  : $PublishFile" 
    Write-host "Variables                : $($Variables -join ' ')" 
    Write-host "TargetTimeout            : $TargetTimeout" 
    Write-host "CommandTimeout           : $CommandTimeout" 
    Write-host "SQLPackagePath           : $sqlpackagePath" 
    Write-host "TargetUser               : $Username" 
    Write-host "TargetPassword           : *************" 

}