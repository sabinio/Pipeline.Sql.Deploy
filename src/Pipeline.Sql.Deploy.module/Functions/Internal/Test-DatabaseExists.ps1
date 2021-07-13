function Test-DatabaseExists {  
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns","", Justification="Exists is not plural..build")]
    [CmdletBinding()]
    param([string]$TargetServer
        , [string]$TargetUser
        , [securestring]$TargetPasswordSecure
        , [string]$TargetDatabaseName)

        $CountOfMatchingDBs= Invoke-SqlScalar -Query "Select count(1) from sys.databases where name = '$TargetDatabaseName'" `
            -DatabaseName "master" `
            -TargetServer $TargetServer `
            -TargetUser $TargetUser `
            -TargetPasswordSecure $TargetPasswordSecure
            
        return ($CountOfMatchingDBs -eq 1)
}