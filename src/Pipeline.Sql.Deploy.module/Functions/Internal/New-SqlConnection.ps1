Function New-SqlConnection {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Justification = "This doesn't need process")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "Target Credentials is used in dynamic script")]
    [Cmdletbinding()]
    param(
        [string] $ConnectionString
    )
    Write-Verbose "Getting New Sql Connection"

    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
   
    $SqlConnection.ConnectionString = $ConnectionString
    
    Write-Verbose "Opening connection"
    $SqlConnection.Open()

    $SqlConnection
}