Function Invoke-DatabaseDacpacDeploy {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter","",Justification= "OutputDeployScript is reported as not being used but it is")]

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$dacpacfile,
        [Parameter(Mandatory=$true)]
        [string]$sqlpackagePath,
        [Parameter(Mandatory=$true)]
        [string]$action,
        [Parameter(Mandatory=$true)]
        [string]$scriptParentPath,
        [Parameter(Mandatory=$true)]
        [string]$TargetServerName,
        [Parameter(Mandatory=$true)]
        [string]$TargetDatabaseName,
        [string]$TargetUser,
        [securestring]$TargetPasswordSecure, 
        [string]$TargetIntegratedSecurity ,

        $ServiceObjective,

        [string]$PublishFile,
        [Switch]$OutputDeployScript,
        [Parameter(Mandatory=$true)]
        $Variables,
        [Parameter(Mandatory=$true)]
        $TargetTimeout,
        [Parameter(Mandatory=$true)]
        $CommandTimeout,
        $SettingsToCheck
    )

    try {
        if ($TargetUser) {
            #Used to be able to extract the password and pass to SQLPackage
            $TargetCredentials = New-Object System.Management.Automation.PSCredential($TargetUser, $TargetPasswordSecure )
            $Security = "/TargetUser:$($TargetCredentials.UserName)", "/TargetPassword:`$(`$TargetCredentials.GetNetworkCredential().Password)"
        }
        else {
            $TargetIntegratedSecurity = $true
            $Security = @()
        }
               
        Write-DBDeployParameterLog  -dacpacfile	$dacpacfile `
                                    -action $action `
                                    -TargetServerName $TargetServerName `
                                    -TargetDatabaseName $TargetDatabaseName `
                                    -TargetIntegratedSecurity $TargetIntegratedSecurity `
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


        $TargetDatabase = "/TargetServerName:$TargetServerName", "/TargetDatabaseName:$TargetDatabaseName"

        $sqlPackageCommand = @()
        $sqlPackageCommand += "/Action:$Action" 

        if ($PublishFile) {
            $sqlPackageCommand += "/Profile:$publishFile"
        }
        
        $sqlPackageCommand += "/SourceFile:$dacpacFile"

        $sqlPackageCommand += "/v:DeployProperties=`"$(Convert-ToSQLPackageSafeString $DeployProperties)`""
        
        if($ServiceObjective){
            $sqlPackageCommand += "/p:DatabaseServiceObjective=$ServiceObjective"
        }

        $sqlPackageCommand += "/TargetTimeout:$TargetTimeout"
        
        if ($Action -eq "Publish"){
            $sqlPackageCommand += "/DeployScriptPath:{0}" -f [IO.Path]::Combine($ScriptParentPath,$TargetDatabaseName,"db.sql")
        }
        elseif($Action -eq "Script"){
            $sqlPackageCommand += "/OutputPath:{0}" -f [IO.Path]::Combine($ScriptParentPath,$TargetDatabaseName,"db.sql")
        }

        $sqlPackageCommand += "/p:CommandTimeout=$CommandTimeout "
        $sqlPackageCommand += $Security
        $sqlPackageCommand += $Variables
        $sqlPackageCommand += $TargetDatabase 
      #  $sqlPackageCommand +="/p:CommentOutSetVarDeclarations=true"
        New-Item $ScriptParentPath\$TargetDatabaseName -ItemType "Directory" -Force | Out-null
        
        if ($env:SYSTEM_DEBUG) {
            $sqlPackageCommand, "/OutputPath:$ScriptPath"
        }

        Function Get-SqlPackageArgument  
        {
            $sqlPackageCommand  | ForEach-Object {
                if ($_ -like "/v:DeployProperties"){
                    $_
                }else{
                    $ExecutionContext.InvokeCommand.ExpandString($_)
                }
            }
        }
        (Get-SqlPackageArgument) | ForEach-Object{ Write-Verbose $_}

        $ErrorActionPreference ="Continue"
        
        invoke-command -ScriptBlock {
            &$sqlpackagePath (Get-SqlPackageArgument)  2>&1 #Ensure errors are sent to the errorvariable
            $LASTEXITCODE
        } -ev sqlpackageerror -OutVariable  SqlPackageExitCode
        $ErrorActionPreference ="Stop"
        
        if ($sqlpackageerror) {
            throw $sqlpackageerror
        }
        $result =[PscustomObject]@{Scripts=Get-ChildItem "$ScriptParentPath\$TargetDatabaseName" -File -Recurse}

        if ($OutputDeployScript){
            $result.Scripts | ForEach-Object {

                Write-Host "######################################### DB Deploy Script ######################################" 
                Write-Host "Produced file $_"
                Write-Host "-------------------------------------------------------------------------------------------------" 
                Get-Content $_.FullName | ForEach-Object { 
                    if ($_ -notlike ':setvar DedployProperties*') {Write-Host $_}
                    else {Write-host ":setvar DeployProperties ### masked ####"}
                }
            }
        }
        return $result
    }
    Catch {
        Throw $_
    }
}