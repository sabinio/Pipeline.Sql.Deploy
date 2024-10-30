foreach ($function in (Get-ChildItem "$PSScriptRoot\Functions\*.ps1"))
{
	Write-Verbose "Loading $($function.basename)"
    . $function
}

foreach ($function in (Get-ChildItem "$PSScriptRoot\Functions\Internal\*.ps1"))
{
	Write-Verbose "Loading $($function.basename)"
    . $function
}