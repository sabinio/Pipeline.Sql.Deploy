Function Write-DbDeployParameterLog {
    [CmdletBinding()]
    param(
        [string] $dacpacfile,
        [string] $action,
        [string] $TargetServerName,
        [string] $TargetDatabaseName,
        [string] $TargetConnectionString,
        [string] $TargetIntegratedSecurity,
        [string] $EntraSecurity,
        [string] $ServiceObjective,
        [string] $PublishFile,
        [string[]] $Variables,
        [string] $TargetTimeout,
        [string] $CommandTimeout,
        [string] $sqlpackagePath,
        [string] $Username,
        [string] $scriptParentPath
    )

    Write-host "Deploying database to server" 
    Write-host "DacpacFile               : $dacpacfile" 
    Write-host "Action                   : $action" 
    if($TargetServerName -ne $null){
        Write-host "TargetServerName         : $TargetServerName" 
        Write-host "TargetDatabaseName       : $TargetDatabaseName" 
    }
    else {
        Write-host "TargetConnectionString   : $TargetConnectionString" 
    }
    Write-host "TargetIntegratedSecurity : $TargetIntegratedSecurity" 
    Write-host "EntraSecurity            : $EntraSecurity"
    Write-host "ServiceObjective         : $ServiceObjective"
    Write-host "Profile                  : $PublishFile" 
    Write-host "Variables                : $($Variables -join ' ')" 
    Write-host "TargetTimeout            : $TargetTimeout" 
    Write-host "CommandTimeout           : $CommandTimeout" 
    Write-host "SQLPackagePath           : $sqlpackagePath" 
    Write-host "TargetUser               : $Username" 
    write-host "scriptParentPath         : $scriptParentPath"
    Write-host "TargetPassword           : *************" 

}