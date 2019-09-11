$infraDescription = (get-content "$PSScriptRoot\tests.json" | Out-String) | ConvertFrom-json

$infraDescription.resources.psobject.properties | ForEach-Object { 
    $resourceType = $_.name
    ForEach($resource in $_.value)
    {
        $exist = Get-AzResource -name $resource -resourceType $resourceType
        if($exist -eq $null)
        {
            write-host "$resource does not exist"
        }

    }
}
