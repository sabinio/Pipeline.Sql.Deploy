function Get-ConnectionString{
    [Cmdletbinding()]
        param(
    [Parameter(ParameterSetName = 'Integrated Security')]
    [Parameter(ParameterSetName = 'UsernamePassword')]
    [Parameter(ParameterSetName = 'Credential')]
    [string] $TargetServer,
    [Parameter(Mandatory = $false,ParameterSetName = 'Integrated Security')]
    [Parameter(Mandatory = $false,ParameterSetName = 'UsernamePassword')]
    [Parameter(Mandatory = $false,ParameterSetName = 'Credential')]
    [string] $DatabaseName,
     [Parameter(Mandatory = $true,ParameterSetName = 'UsernamePassword')]
     [Parameter(Mandatory = $false,ParameterSetName = 'Integrated Security')]
     [string] $TargetUser,
     [Parameter(Mandatory = $true, ParameterSetName = 'UsernamePassword')]
     [securestring] $TargetPasswordSecure,
     [Parameter(Mandatory = $true,ParameterSetName = 'Credential')]
     [pscredential] $Credential
    )

    if (-not [string]::IsNullOrEmpty($TargetUser) -or $null -ne $Credential) {
        if ($null -eq $Credential) {
            $TargetCredentials = New-Object System.Management.Automation.PSCredential($TargetUser, $TargetPasswordSecure )
        }
        else {
            $TargetCredentials = $Credential
        }
        $connectionString = "Server=$TargetServer;Database=$DatabaseName;User ID=$($TargetCredentials.UserName);Password=`$(`$TargetCredentials.GetNetworkCredential().Password)"
    }
    else {
        $connectionString = "Server=$TargetServer;Database=$DatabaseName;trusted_connection=true"    
    }
   
    $connectionString += ";Connect Timeout=2"
    Write-Verbose "Connection String $connectionString"
    return $ExecutionContext.InvokeCommand.ExpandString($connectionString);
}