function Add-ToList{
    param(
        [Parameter(Mandatory = $true,Position=0)]
        $list, 
        [Parameter(ParameterSetName = "item", Mandatory = $true,Position=1)]
        [string]$item
    ,
    [Parameter(ParameterSetName = "list of Items", Mandatory = $true)]
    $items
    )
    if ($PSCmdlet.ParameterSetName -eq "item"){
        $list.Add($item);
    }
    else{
        foreach ( $item in $items){$list.Add($item)}
    }
}