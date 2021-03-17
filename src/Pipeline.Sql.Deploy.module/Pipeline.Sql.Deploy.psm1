foreach ($function in (Get-ChildItem "$PSScriptRoot\Functions\*.ps1"))
{
	Write-Verbose "Loading $($function.basename)"
	$ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create([io.file]::ReadAllText($function))), $null, $null)
}

foreach ($function in (Get-ChildItem "$PSScriptRoot\Functions\Internal\*.ps1"))
{
	Write-Verbose "Loading $($function.basename)"
	$ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create([io.file]::ReadAllText($function))), $null, $null)
}
