Function New-SqlConnection {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Justification = "This doesn't need process")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "Target Credentials is used in dynamic script")]
    [Cmdletbinding()]
    param(
        [string] $TargetServer,
        [string] $DatabaseName,
        [string] $TargetUser,
        [securestring] $TargetPasswordSecure,
        [pscredential] $Credential
    )
    Write-Verbose "Getting New Sql Connection"

    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection

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
    $SqlConnection.ConnectionString = $ExecutionContext.InvokeCommand.ExpandString($connectionString);

    Write-Verbose "Opening connection"
    $SqlConnection.Open()

    $SqlConnection
}