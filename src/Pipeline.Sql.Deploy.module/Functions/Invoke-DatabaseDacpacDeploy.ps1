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

        $sqlPackageCommand = New-Object Collections.Generic.List[String]
        Add-ToList $sqlPackageCommand "/Action:$Action"

        if ($PublishFile) {
            Add-ToList $sqlPackageCommand "/Profile:$publishFile"
        }
        
        Add-ToList $sqlPackageCommand "/SourceFile:$dacpacFile"

        Add-ToList $sqlPackageCommand "/v:DeployProperties=`"$(Convert-ToSQLPackageSafeString $DeployProperties)`""
        
        if($ServiceObjective){
            Add-ToList $sqlPackageCommand "/p:DatabaseServiceObjective=$ServiceObjective"
        }

        Add-ToList $sqlPackageCommand "/TargetTimeout:$TargetTimeout"
        
        if ($Action -eq "Publish"){
            Add-ToList $sqlPackageCommand ("/DeployScriptPath:{0}" -f [IO.Path]::Combine($ScriptParentPath,$TargetDatabaseName,"db.sql"))
        }
        elseif($Action -eq "Script"){
            Add-ToList $sqlPackageCommand ("/OutputPath:{0}" -f [IO.Path]::Combine($ScriptParentPath,$TargetDatabaseName,"db.sql"))
        }

        Add-ToList $sqlPackageCommand "/p:CommandTimeout=$CommandTimeout"
        Add-ToList $sqlPackageCommand -items $Security
        Add-ToList $sqlPackageCommand -items $Variables
        Add-ToList $sqlPackageCommand -items $TargetDatabase 
      #  $sqlPackageCommand +="/p:CommentOutSetVarDeclarations=true"
        New-Item $ScriptParentPath\$TargetDatabaseName -ItemType "Directory" -Force | Out-null
        
        if ($env:SYSTEM_DEBUG) {
            $sqlPackageCommand
        }

        Function Get-SqlPackageArgument  
        {
            $sqlPackageCommand  | ForEach-Object {
                if ($_ -like "*/v:DeployProperties*"){
                    $_
                }else{
                    $ExecutionContext.InvokeCommand.ExpandString($_)
                }
            }
        }
        (Get-SqlPackageArgument) | ForEach-Object{ Write-Verbose $_}

        $ErrorActionPreference ="Continue"
        
        $LASTEXITCODE = 0

        invoke-command -ScriptBlock {
               &$sqlpackagePath (Get-SqlPackageArgument)   #Ensure errors are sent to the errorvariable
        } -ev sqlpackageerror -OutVariable  SqlPackageExitCode 

        $ErrorActionPreference ="Stop"
        
        if ($Global:LASTEXITCODE -ne 0) {
            throw "SqlPackage returned non-zero exit code: $LASTEXITCODE"
        }
        
        $result =[PscustomObject]@{Scripts=Get-ChildItem "$ScriptParentPath\$TargetDatabaseName" -File -Recurse}

        if ($OutputDeployScript){
            $result.Scripts | ForEach-Object {

                Write-Host "######################################### DB Deploy Script ######################################" 
                Write-Host "Produced file $_"
                Write-Host "-------------------------------------------------------------------------------------------------" 
                Get-Content $_.FullName | ForEach-Object { 
                    if ($_ -notlike '*:setvar DeployProperties*') {Write-Host $_}
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