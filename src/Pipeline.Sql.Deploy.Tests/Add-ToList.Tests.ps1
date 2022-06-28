
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

Describe 'Add To list' {
    It 'Should add an item to list' {
        $List = new-object System.Collections.Generic.List[string]
        Add-ToList -list $List -item "Item1"
        $list[0] | should -be "Item1"

    }

    It 'Should add an item to list' {
        $List = new-object System.Collections.Generic.List[string]
        Add-ToList -list $List -items ("Item1","Item2")
        $list[0] | should -be "Item1"
        $list[1] | should -be "Item2"

    }
}
