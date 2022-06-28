BeforeDiscovery{
    Write-Verbose "Module path Beforedisco - $ModulePath"-verbose
}
BeforeAll {
	Set-StrictMode -Version 1.0
    if (-not (Test-path  Variable:\ProjectName)) { $ProjectName = (get-item $PSScriptRoot).basename -replace ".tests", "" }
    $CommandName = [IO.Path]::GetFileName($PSCommandPath).Replace(".Tests.ps1", "")
    
    if (-not (Test-path  Variable:\ModulePath) -or "$ModulePath" -eq "") {$ModulePath = "$PSScriptRoot\..\$ProjectName.module" }
    #. $ModuleBase\functions\$CommandName
    Write-Verbose "Module path Beforeall after - $ModulePath" -verbose

    get-module $ProjectName | Remove-Module -Force
    Get-ChildItem ([System.IO.Path]::Combine($ModulePath,"Functions","*.ps1")) -Recurse | ForEach-Object{
         Write-Verbose "loading $_" -Verbose;
       . $_.FullName
    }
}

Describe 'Invoke-scalar' {
    It 'should make connection to the server specified' {
        [string] $Server = "bob"
        [string] $DBName = "dbbob"
        [string] $User = "oddman"

        $pwd = ("insecure " | ConvertTo-SecureString -AsPlainText -Force)
        
        Mock Invoke-SqlScalarInternal
        Mock Close-SqlConnection
        Mock New-SqlConnection 

        Invoke-SqlScalar -TargetServer $Server -DatabaseName $DBName -TargetUser $User -TargetPasswordSecure $pwd -Query "select 1" 

        Assert-MockCalled New-SqlConnection -ParameterFilter { $ConnectionString -like "*Server=$Server*" } -Exactly 1 
    }
}
