Function Test-ShouldDeployDacpac {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification = "Need to cater for users that ")]
    [CmdletBinding()]
    param (
        $settings,
        [string]$dacpacfile,
        [string]$publishFile,
        [string]$DBDeploySettingsFile
    )
    
    $shouldDeploy = $false
    $TargetUser = ""
    $TargetServer = ""
    $TargetPasswordSecure = $null

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
    if ($publishFile) {
        Write-Host "Publish File is not currently used to check if settings have changed. Consider adding publish file as a value in the settings parameter"
    }
    #Check date of dacpac against last deployment time
    $dacpacDate = (Get-Item $dacpacfile).LastWriteTimeUtc
    
    try {
        Write-Host "Checking if we should deploy database"
        $databaseExists = Test-DatabaseExists `
            -TargetServer $TargetServer `
            -TargetUser $TargetUser `
            -TargetPasswordSecure $TargetPasswordSecure `
            -TargetDatabaseName $TargetDatabaseName

        Write-Verbose "Database exists query result ($databaseExists)"
        if (-not $databaseExists) {
            Write-Host "Should deploy because database doesn't exist"
            $shouldDeploy = $true
        }
        else {
            #Get latest deploy for the required dacpac
            if ($null -eq $DBDeploySettingsFile) {
          
              <#  $dacpacname = (Get-Item $dacpacfile).basename 
                $DeployProperties = Invoke-SqlScalar -Query "Select DeployProperties from Deploy.Deployment order by DeploymentCreated Desc
             #  where json_value(DeployProperties,'$.Parameters.dacpacname') = $dacpacName" `
                    -DatabaseName $TargetDatabaseName `
                    -TargetServer $TargetServer `
                    -TargetUser $TargetUser `
                    -TargetPasswordSecure $TargetPasswordSecure

                if ($DeployProperties)
                Write-Verbose "Last deployment $LastDeployDate - dacpac date $dacpacDate"
#>
            }
            else {
                #previous behaviour using a DBDeploySettingsFile 

                if (Test-IsPreviousDeploySettingsFileMissing -DBDeploySettingsFile $DBDeploySettingsFile) {
                    Write-Host "ShouldDeploy? Yes - no settings file"            
                    $shouldDeploy = $true
                }
                elseif (Test-HaveDeploySettingsChangedSinceLastDeploy -DBDeploySettingsFile $DBDeploySettingsFile -Settings $Settings) {
                    Write-Host "ShouldDeploy? Yes - settings have changed"
                    $shouldDeploy = $true
                }
                else {
                    $LastDeployDate = Invoke-SqlScalar -Query "Select top 1 DeploymentCreated from Deploy.Deployment order by DeploymentCreated Desc" `
                        -DatabaseName $TargetDatabaseName `
                        -TargetServer $TargetServer `
                        -TargetUser $TargetUser `
                        -TargetPasswordSecure $TargetPasswordSecure
                    if ($null -eq $LastDeployDate -or $LastDeployDate -lt $dacpacDate) {
                        Write-Host "last deploy date > dacpac date so we don't need to deploy the database"
                        $shouldDeploy = $true
                    }
                }
            }
    
        }
    }
    catch {
        Write-Host "Error Occurred -verbose logging for more detail if required"
        Write-Verbose  ($_ | Format-Table | Out-String)
        $shouldDeploy = $true
    }

    Write-Verbose "Returning from Test-ShouldDeployDacpac with `$shouldDeploy = $shouldDeploy"

    return $shouldDeploy
}