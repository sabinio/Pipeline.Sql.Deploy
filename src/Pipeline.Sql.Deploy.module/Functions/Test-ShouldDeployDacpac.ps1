Function Test-ShouldDeployDacpac {
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText","",Justification="Need to cater for users that ")]
    [CmdletBinding()]
    param (
        $settings,
        [string]$dacpacfile,
        [string]$publishFile,
        [string]$DBDeploySettingsFile
    )
    
    $shouldDeploy = $true
    $TargetUser=""
    $TargetServer=""
    $TargetPasswordSecure=$null

    if ($settings.sqlAdminLogin) {
        $TargetUser = $settings.sqlAdminLogin
        $TargetPasswordSecure = $settings.sqlAdminPassword | ConvertTo-SecureString -AsPlainText -Force
    }
    if ($settings.TargetUser) {
        $TargetUser = $settings.TargetUser
        $TargetPasswordSecure = $settings.TargetPasswordSecure
    }

    if ($settings.TargetDatabaseName) {
        $TargetDatabaseName = $settings.TargetDatabaseName
    }

    if ($settings.serverName) {
        $TargetServer = $settings.serverName
    }
    if ($settings.TargetServerName) {
        $TargetServer = $settings.TargetServerName
    }
    if ($publishFile){
        Write-Host "Publish File is not currently used to check if settings have changed. Consider adding publish file as a value in the settings parameter"
    }
    #Check date of dacpac against last deployment time
    $dacpacDate = (Get-Item $dacpacfile).LastWriteTimeUtc
    
    try {
        Write-Host "Checking if we should deploy database"
        # assume need to deploy
        if (Test-IsPreviousDeploySettingsFileMissing -DBDeploySettingsFile $DBDeploySettingsFile) {
            Write-Host "ShouldDeploy? Yes - no settings file"            
            $shouldDeploy = $true
        }elseif (Test-HaveDeploySettingsChangedSinceLastDeploy -DBDeploySettingsFile $DBDeploySettingsFile -Settings $Settings) {
            Write-Host "ShouldDeploy? Yes - settings have changed"
            $shouldDeploy = $true
        }else {
    
            $databaseExists = Invoke-SqlScalar -Query "Select top 1 name from sys.databases where name = '$TargetDatabaseName'" `
                                               -DatabaseName "master" `
                                               -TargetServer $TargetServer `
                                               -TargetUser $TargetUser `
                                               -TargetPasswordSecure $TargetPasswordSecure
        
            Write-Verbose "Database exists query result ($databaseExists)"
            if ($databaseExists -eq $TargetDatabaseName) {

                $LastDeployDate = Invoke-SqlScalar -Query "Select top 1 DeploymentCreated from Deploy.Deployment order by DeploymentCreated Desc" `
                                                   -DatabaseName $TargetDatabaseName `
                                                   -TargetServer $TargetServer `
                                                   -TargetUser $TargetUser `
                                                   -TargetPasswordSecure $TargetPasswordSecure
            
                Write-Verbose "Last deployment $LastDeployDate - dacpac date $dacpacDate"
            
                if ($LastDeployDate -and $LastDeployDate -gt $dacpacDate) {
                    Write-Host "last deploy date > dacpac date so we don't need to deploy the database"
                    $shouldDeploy = $false
                }
            }
            else {
                Write-Host "Database does not exist so we need to deploy it."
                $shouldDeploy = $true    
            }
        }
    }
    catch {
        Write-Host "Error Occurred -verbose logging for more detail if required"
        Write-Verbose  ($_ | Format-Table | Out-String)
    }

    Write-Verbose "Returning from Test-ShouldDeployDacpac with `$shouldDeploy = $shouldDeploy"

    return $shouldDeploy
}