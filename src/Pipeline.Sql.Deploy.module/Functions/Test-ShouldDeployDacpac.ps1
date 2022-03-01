Function Test-ShouldDeployDacpac {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification = "Need to cater for users that want to pass strings ")]
    [CmdletBinding()]
    param (
        $settings,
        $SettingsToCheck,
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
    if ($null -eq $settings.publishFile){
        $settings.publishFile = $publishFile
    }
    if ($null -ne $Settings.publishFile) {
        Write-Host "Publish File is not currently used to check if settings have changed. Consider adding publish file as a value in the settings parameter"
    }
    
    #Check date of dacpac against last deployment time
    $dacpacDate = (Get-Item $dacpacfile).LastWriteTimeUtc
    
    if  ($null -eq $SettingsToCheck){
        $SettingsToCheck = Get-DefaultSettingsToCheck -dacpacfile $dacpacfile  @settings     
    }

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
            if ([string]::IsNullOrWhiteSpace($DBDeploySettingsFile)) {

          
                $dacpacname = (Get-Item $dacpacfile).basename 

                $SettingsFromDB = Get-DeploySettingsFromDB -DacpacName $dacpacName -Server $TargetServer -User $TargetUser -PasswordSecure $TargetPasswordSecure -Database $TargetDatabaseName
                
                if ($null -eq $SettingsFromDB) {
                    Write-Host "no settings in DB need to deploy"
                    $shouldDeploy = $true
                }
                elseif (Test-HaveDeploySettingsChangedSinceLastDeploy -OldSettings $SettingsFromDB.SettingsToCheck -Settings $SettingsToCheck) {
                    Write-Host "ShouldDeploy? Yes - settings have changed"
                    $shouldDeploy = $true
                }
                elseif ($SettingsFromDB.LastDeployDate -lt $dacpacDate) {
                    Write-Host "last deploy date < dacpac date so we don't need to deploy the database"
                    $shouldDeploy = $true
                }   
            }
            else {
                #previous behaviour using a DBDeploySettingsFile 

                if (Test-IsPreviousDeploySettingsFileMissing -DBDeploySettingsFile $DBDeploySettingsFile) {
                    Write-Host "ShouldDeploy? Yes - no settings file"            
                    $shouldDeploy = $true
                }
                elseif (Test-HaveDeploySettingsChangedSinceLastDeploy -OldSettings (Get-DeploySettingsFromFile -DBDeploySettingsFile $DBDeploySettingsFile ) -Settings $SettingsToCheck) {
                    Write-Host "ShouldDeploy? Yes - settings have changed"
                    $shouldDeploy = $true
                }
                else {
                    $dacpacname = (Get-Item $dacpacfile).basename 

                    $SettingsFromDB = Get-DeploySettingsFromDB -DacpacName $dacpacName -Server $TargetServer -User $TargetUser -PasswordSecure $TargetPasswordSecure -Database $TargetDatabaseName
                    
                    if ($null -eq $SettingsFromDB ) {
                        Write-Host "no settings found in Db for $dacpacname"
                        $shouldDeploy = $true
                    }
                    elseif ($SettingsFromDB.LastDeployDate -lt $dacpacDate) {
                        Write-Host "last deploy date < dacpac date so we don't need to deploy the database"
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

    Write-Verbose "Returning from Test-ShouldDeployDacpac with ,$shouldDeploy = $shouldDeploy"

    return $shouldDeploy
}