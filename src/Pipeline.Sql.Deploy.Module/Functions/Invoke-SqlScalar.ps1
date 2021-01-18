Function Invoke-SqlScalar {
    [cmdletbinding()]
    param(
        [string] $TargetServer,    
        [string] $DatabaseName,
        [string] $TargetUser,
        [securestring] $TargetPasswordSecure,
        [string] $Query
        )
    
    $con = New-SqlConnection -TargetUser $TargetUser -TargetPasswordSecure $TargetPasswordSecure -DatabaseName $DatabaseName -TargetServer $TargetServer
    
    Invoke-SqlScalarInternal -Connection $con -Query $Query 

    Close-SqlConnection $con
} 
Function Close-SqlConnection{
    [cmdletbinding()]
    param(
         $Connection   
    )
    Write-Verbose "Close Connection"
    $connection.Close();
}

Function Invoke-SqlScalarInternal {
    [cmdletbinding()]
    param(
         $Connection,    
        [string] $Query)

    Write-Verbose "Invoke-SqlScalar $Query"
    $SqlCommand = New-Object System.Data.SqlClient.SqlCommand
    $SqlCommand.Connection = $connection
    $SqlCommand.CommandText = $Query;
    Write-Verbose "Execute query"
    $SqlCommand.ExecuteScalar();
    }