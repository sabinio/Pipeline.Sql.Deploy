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
}

Describe 'Invoke-scalar' {
    It 'should run correct query against the servermake connection to the server specified' {
        [string] $Server = "bob"
        [string] $DBName = "dbbob"
        [string] $User = "oddman"

        $pwd = ("insecure " | ConvertTo-SecureString -AsPlainText -Force)
        
        Mock Invoke-SqlCmd { @{DeploymentCreated=(get-date);DeployPropertiesJSON=""} }

        Get-DeploySettingsFromDB -Server $Server -Database $DBName -User $User -Password $pwd -DacpacName "test"

        Should -invoke Invoke-SqlCmd -Exactly 1 
        Should -invoke Invoke-SqlCmd -Exactly 1 -ParameterFilter { $Query -eq "Select top 1 DeploymentCreated, DeployPropertiesJSON from Deploy.Deployment  where json_value(DeployPropertiesJSON,'$.Parameters.dacpacname') = 'test' order by DeploymentCreated Desc" }
        Should -invoke Invoke-SqlCmd -Exactly 1 -ParameterFilter { $Database -eq $DbName }
        Should -invoke Invoke-SqlCmd -Exactly 1 -ParameterFilter { $server -eq $Server }
    }
    It 'should run and connect with sql auth with correct password' {
        [string] $Server = "bob"
        [string] $DBName = "dbbob"
        [string] $User = "oddman"

        $pwd = ("insecure" | ConvertTo-SecureString -AsPlainText -Force)
        
        Mock Invoke-SqlCmd { @{DeploymentCreated=(get-date);DeployPropertiesJSON=""} }

        Get-DeploySettingsFromDB -Server $Server -Database $DBName -User $User -Password $pwd -DacpacName "test"

        Should -invoke Invoke-SqlCmd -Exactly 1 
        Should -invoke Invoke-SqlCmd -Exactly 1 -ParameterFilter { $Credential.username -eq $user }
        Should -invoke Invoke-SqlCmd -Exactly 1 -ParameterFilter { $Credential.GetNetworkCredential().Password -eq "insecure" }
    }
    
    It 'should run and connect with integrated auth' {
        [string] $Server = "bob"
        [string] $DBName = "dbbob"

        Mock Invoke-SqlCmd { @{DeploymentCreated=(get-date);DeployPropertiesJSON=""} }

        Get-DeploySettingsFromDB -Server $Server -Database $DBName  -DacpacName "test"

        Should -invoke Invoke-SqlCmd -Exactly 1 
        Should -invoke Invoke-SqlCmd -Exactly 1 -ParameterFilter { $Credential -eq $null }
    }
}
