
BeforeDiscovery{
}
BeforeAll {
	Set-StrictMode -Version 1.0
    if (-not (Test-path  Variable:\ProjectName)) { $ProjectName = (get-item $PSScriptRoot).basename -replace ".tests", "" }
    $CommandName = [IO.Path]::GetFileName($PSCommandPath).Replace(".Tests.ps1", "")
    Write-verbose "Loading $CommandName  file" -Verbose
    
    try{
        if (-not (Test-path  Variable:\ModulePath) -or "$ModulePath" -eq "") {$ModulePath = "$PSScriptRoot\..\$ProjectName.module" }
    #. $ModuleBase\functions\$CommandName
        $FunctionFile = [System.IO.Path]::Combine($ModulePath,"Functions","Internal","$CommandName.ps1")
        get-module $ProjectName | Remove-Module -Force
        . $FunctionFile
    }
    catch{
        Write-Verbose $_.Exception.Message -Verbose 
    }
}

Describe 'Get-ConnectionString' {
    It 'should use password and username if passed as credential' {
        $credential = New-Object System.Management.Automation.PSCredential("Username", ("mypwd" | ConvertTo-SecureString -AsPlainText -Force))
        
        $string = Get-ConnectionString -credential $credential 
        $string | Should -belike "*password=mypwd*"
        $string | Should -BeLike "*User Id=Username*"
    }
    It 'should use username and password if passed in' {
        $pwd = "mypwd" | ConvertTo-SecureString -AsPlainText -Force
        
        $string = Get-ConnectionString -TargetUser "Username" -TargetPasswordSecure $pwd
        $string | Should -belike "*password=mypwd*"
        $string | Should -BeLike "*User Id=Username*"
    }
    
    It 'should use trusted_connection=true if no username or credntial is passed"' {
        $pwd = "mypwd" | ConvertTo-SecureString -AsPlainText -Force
        
        $string = Get-ConnectionString -TargetServer "." -DatabaseName "sdfs"
        $string | Should -belike "*trusted_connection=true*"
    }
    
    It 'should error if try to use username or  password and credential' {
        $pwd = "mypwd" | ConvertTo-SecureString -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential("Username", ("mypwd" | ConvertTo-SecureString -AsPlainText -Force))
        
        {Get-ConnectionString -TargetUser "Username" -TargetPasswordSecure $pwd -credential  $credential } | Should -Throw
        {Get-ConnectionString -TargetUser "Username"  -credential  $credential } | Should -Throw
        {Get-ConnectionString -TargetPasswordSecure $pwd -credential  $credential } | Should -Throw
    }
}
