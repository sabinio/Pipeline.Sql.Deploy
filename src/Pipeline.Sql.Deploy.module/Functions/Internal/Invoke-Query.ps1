Function Invoke-Query {
    [cmdletbinding()]
    param(
        [parameter()]
        [string] $ServerInstance,    
        [string] $Database,
        [string] $TargetUser,
        [securestring] $TargetPasswordSecure,
        [pscredential] $Credential,
        [string] $Query,
        $MaxCharLength
        )
    
    if ($MaxCharLength) {
     write-host "MaxCharLength is ignored in Invoke-query"
    }
    $Params = @{DatabaseName = $Database; TargetServer = $ServerInstance }
    if (-not [String]::IsNullOrWhiteSpace($TargetUser)) {
        $params.TargetUser = $TargetUser;
        $params.TargetPassword = $TargetPasswordSecure;
    }
    elseif ($credential){
        $params.Credential = $Credential;
    }

    $conString = Get-ConnectionString @params
    $Con = new-sqlConnection -ConnectionString $conString
    try{
    Invoke-QueryInternal -Connection $con -Query $Query 
    }
    finally {
        Close-SqlConnection $con
    }
} 
Function Close-SqlConnection{
    [cmdletbinding()]
    param(
         $Connection   
    )
    Write-Verbose "Close Connection"
    if ($null -ne $connection)
    {  
        $connection.Close();
        $connection.Dispose();
    }
}

Function Invoke-QueryInternal {
    [cmdletbinding()]
    param(
         $Connection,    
        [string] $Query)

    Write-Verbose "Invoke-SqlScalar $Query"
    $SqlCommand = New-Object System.Data.SqlClient.SqlCommand
    $SqlCommand.Connection = $connection
    $SqlCommand.CommandText = $Query;
    Write-Verbose "Execute query"
    $results = New-Object System.Data.DataTable
    $sqladapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $sqladapter.SelectCommand = $SqlCommand
    [void]$sqladapter.Fill($results)
    return $Results

    }