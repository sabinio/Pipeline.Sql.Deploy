Function Invoke-DatabaseDacpacDeploy {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification = "OutputDeployScript is reported as not being used but it is")]

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$dacpacfile,
        [Parameter(Mandatory = $true)]
        [string]$sqlpackagePath,
        [Parameter(Mandatory = $true)]
        [string]$action,
        [Parameter(Mandatory = $true)]
        [string]$scriptParentPath,
        #Parameter set TargetServer and Database or ConnectionString
        [Parameter(Mandatory = $true, ParameterSetName = "IndividualTarget")]
        [string]$TargetServerName,
        [Parameter(Mandatory = $true, ParameterSetName = "IndividualTarget")]
        [string]$TargetDatabaseName,
        [string]$TargetUser,
        [securestring]$TargetPasswordSecure, 
        [string]$TargetIntegratedSecurity ,
        [switch]$TargetTrustServerCert,
        [Parameter(Mandatory = $true, ParameterSetName = "ConnectionStringTarget")]
        [string]$TargetConnectionString,
        $ServiceObjective,
        [String]$AccessToken,
        [SecureString]$AccessTokenSecure,
        [string]$TenantId,
        [string]$ClientId,
        [string]$ClientSecret,
        [securestring]$ClientSecretSecure,
        [string]$PublishFile,
        [Switch]$OutputDeployScript,
        [Parameter(Mandatory = $true)]
        $Variables,
        [Parameter(Mandatory = $true)]
        $TargetTimeout,
        [Parameter(Mandatory = $true)]
        $CommandTimeout,
        $SettingsToCheck,
        [string]$DBScriptPrefix

    )

    try {
        $EntraSecurity = $false
        if ($TargetUser) {
            #Used to be able to extract the password and pass to SQLPackage
            $TargetCredentials = New-Object System.Management.Automation.PSCredential($TargetUser, $TargetPasswordSecure )
            $Security = "/TargetUser:$($TargetCredentials.UserName)", "/TargetPassword:`$(`$TargetCredentials.GetNetworkCredential().Password)"
        }
        else {
            if ($AccessToken -or $AccessTokenSecure -or ( $ClientId -and ( $ClientSecret -or $ClientSecretSecure) -and $TenantId ) ) {
                $EntraSecurity = $true    
            }
             else {
                $TargetIntegratedSecurity = $true
            }
            $Security = @()
        }
               
        Write-DBDeployParameterLog  -dacpacfile	$dacpacfile `
            -action $action `
            -TargetConnectionString $TargetConnectionString `
            -TargetServerName $TargetServerName `
            -TargetDatabaseName $TargetDatabaseName `
            -TargetIntegratedSecurity $TargetIntegratedSecurity `
            -EntraSecurity $EntraSecurity `
            -ServiceObjective $ServiceObjective `
            -PublishFile $PublishFile `
            -Variables $Variables `
            -TargetTimeout $TargetTimeout `
            -CommandTimeout $CommandTimeout `
            -sqlpackagePath $sqlpackagePath `
            -Username $TargetUser `
            -scriptParentPath $scriptParentPath -ErrorAction Stop

        $DeployProperties = Get-DeployPropertiesHash -action $action `
            -TargetServerName $TargetServerName `
            -TargetDatabaseName $TargetDatabaseName `
            -TargetUser $TargetUser `
            -TargetPasswordSecure $TargetPasswordSecure `
            -TargetIntegratedSecurity $TargetIntegratedSecurity `
            -ServiceObjective $ServiceObjective `
            -PublishFile $PublishFile `
            -Variables $Variables `
            -TargetTimeout $TargetTimeout `
            -dacpacfile $dacpacfile	     `
            -SettingsToCheck $SettingsToCheck


        $sqlPackageCommand = New-Object Collections.Generic.List[String]
        Add-ToList $sqlPackageCommand "/Action:$Action"

        Add-ToList $sqlPackageCommand "/TargetTimeout:$TargetTimeout"
        if ([string]::IsNullOrWhiteSpace($DBScriptPrefix) ) { $DBScriptPrefix = [io.path]::GetFileNameWithoutExtension($dacpacfile) }
 
        # Handle database name extraction for path construction - extract database name from connection string if needed
        $DatabaseNameForPath = $TargetDatabaseName
        if ($TargetConnectionString -and [string]::IsNullOrWhiteSpace($TargetDatabaseName)) {
            # Extract database name from connection string
            if ($TargetConnectionString -match "Database=([^;]+)") {
                $DatabaseNameForPath = $matches[1]
            }
            elseif ($TargetConnectionString -match "Initial Catalog=([^;]+)") {
                $DatabaseNameForPath = $matches[1]
            }
            else{
                throw "Unable to extract database name from connection string. Please ensure the connection string contains 'Database' or 'Initial Catalog' parameter."
            }
        }

        if ($TargetConnectionString) {
            Add-ToList $sqlPackageCommand "/TargetConnectionString:$TargetConnectionString"
        }
        else {
            $TargetDatabase = "/TargetServerName:$TargetServerName", "/TargetDatabaseName:$TargetDatabaseName"
        }

        If ($Action -eq "DriftReport") {
            if ($Variables -Contains "/TargetTrustServerCertificate:true"){
                Add-ToList $sqlPackageCommand ("/TargetTrustServerCertificate:True")
            }
            Add-ToList $sqlPackageCommand ("/OutputPath:{0}" -f [IO.Path]::Combine($ScriptParentPath, $DatabaseNameForPath, "$DBScriptPrefix`_drift.xml"))
        }
        else {
            if ($PublishFile) {
                Add-ToList $sqlPackageCommand "/Profile:$publishFile"
            }
                
            if ($ServiceObjective) {
                Add-ToList $sqlPackageCommand "/p:DatabaseServiceObjective=$ServiceObjective"
            }

            Add-ToList $sqlPackageCommand "/SourceFile:$dacpacFile"
    
            Add-ToList $sqlPackageCommand "/v:DeployProperties=`"$(Convert-ToSQLPackageSafeString $DeployProperties)`""
            Add-ToList $sqlPackageCommand -items $Variables

            Add-ToList $sqlPackageCommand "/p:CommandTimeout=$CommandTimeout"

            if ($Action -eq "Publish") {
                Add-ToList $sqlPackageCommand ("/DeployScriptPath:{0}" -f [IO.Path]::Combine($ScriptParentPath, $DatabaseNameForPath, "$DBScriptPrefix`_db.sql"))
            }
            elseif ($Action -eq "Script") {
                Add-ToList $sqlPackageCommand ("/DeployScriptPath:{0}" -f [IO.Path]::Combine($ScriptParentPath, $DatabaseNameForPath, "$DBScriptPrefix`_db.sql"))
            }
        }

        if (-not $TargetConnectionString) {
            Add-ToList $sqlPackageCommand -items $TargetDatabase 
        } 
        
        if ($TargetTrustServerCert) {
            Add-ToList $sqlPackageCommand "/TargetTrustServerCertificate:True"
        }
        
        if ($AccessToken -or $AccessTokenSecure -or ( $ClientId -and ( $ClientSecret -or $ClientSecretSecure) -and $TenantId ) ) {
            if ($AccessTokenSecure -or $AccessToken) {
                Write-Host "Using Access Token provided clientId and secret being ignored"
            }
            else{
                Write-Host "Getting Access Token using ClientId and ClientSecret"
                $AccessToken = (Get-EntraAccessToken -ClientId $ClientId -ClientSecret $ClientSecret -ClientSecretSecure $ClientSecretSecure -TenantId $TenantId).access_token
                Write-Host $AccessToken
            }
            if ($AccessTokenSecure -is [System.Security.SecureString]) {
                    Write-Host "Extracting Access Token from SecureString"
                    $cred = New-Object System.Management.Automation.PSCredential ("user", $AccessTokenSecure)
                    $AccessToken = $cred.GetNetworkCredential().Password
            }
            write-host "Access token first 10 and last 10 characters: $($AccessToken.Substring(0,10))...$($AccessToken.Substring($AccessToken.Length - 10))"

            $Security += "/AccessToken:$AccessToken"
        }
        
        #  $sqlPackageCommand +="/p:CommentOutSetVarDeclarations=true
        New-Item $ScriptParentPath\$DatabaseNameForPath -ItemType "Directory" -Force | Out-null
        
        if ($env:SYSTEM_DEBUG) {
            $sqlPackageCommand
        }

        Add-ToList $sqlPackageCommand -items $Security

        Function Get-SqlPackageArgument {
            $sqlPackageCommand  | ForEach-Object {
                if ($_ -like "*/v:DeployProperties*" ) {
                    $_
                }
                else {
                    $ExecutionContext.InvokeCommand.ExpandString($_)
                }
            }
        }
        (Get-SqlPackageArgument) | ForEach-Object { Write-Verbose $_ }

        $ErrorActionPreference = "Continue"
        
        $LASTEXITCODE = 0
        
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'PS variable  used internally by PS not by our code')]
        $PSNativeCommandArgumentPassing ="legacy" 
        
        invoke-command -ScriptBlock {
            &$sqlpackagePath (Get-SqlPackageArgument)   #Ensure errors are sent to the errorvariable
        } -ev sqlpackageerror -OutVariable  SqlPackageExitCode 

        $ErrorActionPreference = "Stop"
        
        $LEC = $Global:LASTEXITCODE
        
        $result = [PscustomObject]@{Scripts = Get-ChildItem "$ScriptParentPath\$DatabaseNameForPath" -File -Recurse }

        if ($OutputDeployScript) {
            $result.Scripts | ForEach-Object {

                Write-Host "######################################### DB Deploy Script ######################################" 
                Write-Host "Produced file $_"
                Write-Host "-------------------------------------------------------------------------------------------------" 
                Get-Content $_.FullName | ForEach-Object { 
                    if ($_ -notlike '*:setvar DeployProperties*') { Write-Host $_ }
                    else { Write-host ":setvar DeployProperties ### masked ####" }
                }
            }
        }
        IF ($LEC -ne 0  ) {
            #Write error with the exit code from SQLPackage, this will be used by the calling function to determine if the deployment succeeded or failed
            #Proper writeError
            $PSCmdlet.WriteError((New-Object System.Management.Automation.ErrorRecord( 
                (New-Object System.Exception("SqlPackage returned non-zero exit code $LEC")), 
                "SqlPackageDeploymentFailed", [System.Management.Automation.ErrorCategory]::NotSpecified, $null)))


        }
        return $result

    }
    Catch {
        Throw $_
    }
}