
Function Convert-ToSQLPackageSafeString{
    [CmdletBinding()]
    param($Object)
    
        return (ConvertTo-Json $Object -Compress).Replace('"', '@@') -replace "([a-z])\\\\""", "`$1\\\\`"" -replace "\[","&^" -replace "\]","~$"    
}

