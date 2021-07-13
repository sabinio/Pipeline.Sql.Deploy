param(
    $ModulePath,
    $ProjectName
)
BeforeDiscovery{
    Write-Verbose "Module path Beforedisco - $ModulePath"-verbose
}
BeforeAll {
	Set-StrictMode -Version 1.0
    if (-not (Test-path  Variable:\ProjectName)) { $ProjectName = (get-item $PSScriptRoot).basename -replace ".tests", "" }
    $CommandName = [IO.Path]::GetFileName($PSCommandPath).Replace(".Tests.ps1", "")
    
    if (-not (Test-path  Variable:\ModulePath) -or "$ModulePath" -eq "") {$ModulePath = "$PSScriptRoot\..\$ProjectName.module" }
    get-module $ProjectName | Remove-Module -Force
    . $ModulePath\Functions\Internal\$CommandName.ps1
    . $ModulePath\Functions\Internal\Invoke-SqlScalar.ps1
}

Describe 'Test-DatabaseExists' {
    It 'should run correct query against the servermake connection to the server specified' {
        [string] $Server = "bob"
        [string] $DBName = "dbbob"
        [string] $User = "oddman"

        $pwd = ("insecure " | ConvertTo-SecureString -AsPlainText -Force)
        
        Mock Invoke-SqlScalar  { return "foo" }

        Test-DatabaseExists -TargetServer $Server -TargetDatabase $DBName -TargetUser $User -TargetPasswordSecure $pwd 

        Should -invoke Invoke-SqlScalar -Exactly 1 
        Should -invoke Invoke-SqlScalar -Exactly 1 -ParameterFilter { $Query -eq "Select count(1) from sys.databases where name = '$DBName'" }
    }

    It 'should return false if <_> databases found' -TestCases (0,2,3,4)   {
        [string] $Server = "bob"
        [string] $DBName = "dbbob"
        [string] $User = "oddman"

        $pwd = ("insecure " | ConvertTo-SecureString -AsPlainText -Force)
        
        Mock Invoke-SqlScalar  { $_ }

        Test-DatabaseExists -TargetServer $Server -TargetDatabase $DBName -TargetUser $User -TargetPasswordSecure $pwd | should -be $false

        Should -invoke Invoke-SqlScalar -Exactly 1 
        Should -invoke Invoke-SqlScalar -Exactly 1 -ParameterFilter { $Query -eq "Select count(1) from sys.databases where name = '$DBName'" }
    }
    It 'should return true if <_> databases found' -TestCases (1)   {
        [string] $Server = "bob"
        [string] $DBName = "dbbob"
        [string] $User = "oddman"

        $pwd = ("insecure " | ConvertTo-SecureString -AsPlainText -Force)
        $Count = $_
        Mock Invoke-SqlScalar  { 
            $Count 
        }

        Test-DatabaseExists -TargetServer $Server -TargetDatabase $DBName -TargetUser $User -TargetPasswordSecure $pwd | should -be $true

    }
}
