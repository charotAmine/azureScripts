
$batchAccountName = "batchaccountsec"
$rgName = "batchsecurity"
$kvName = "keyvaultsecurity001"
$storageAccountName = "01storagesecurity"
$containerName = "deploy"
$poolName = "poolsecurity"

$batchAccessKey = az batch account keys list --name $batchAccountName --resource-group $rgName --query primary -o tsv
$sasKey = az keyvault secret show --name "$storageAccountName-secret" --vault-name $kvName --query value -o tsv
$key = az storage account keys list -n $storageAccountName --query "[0].{value:value}" -o tsv
$zipFiles = az storage blob list --account-name $storageAccountName --account-key $key -c $containerName --query "[].{name:name}" -o tsv
$resourceFiles = @()
$access = az batch account login --name $batchAccountName --resource-group $rgName --show --query accessToken -o tsv
$uri = "https://$batchAccountName.westeurope.batch.azure.com/pools/$poolName"
foreach($zipFile in $zipFiles)
{
    $storageAccountUri = "https://$storageAccountName.blob.core.windows.net/$containerName/$zipFile"
    $storageAccountUri += $sasKey
    $fileProperties = @{
        "httpUrl" = $storageAccountUri
        "filePath" = $zipFile
    }
    $resourceFiles += $fileProperties
}

$starTask = 'powershell Copy-Item -Path $env:AZ_BATCH_NODE_STARTUP_DIR\wd\* -Destination $env:AZ_BATCH_NODE_ROOT_DIR\applications\ -Force -Recurse -Verbose; Get-ChildItem $env:AZ_BATCH_NODE_ROOT_DIR\applications\*.zip | % {$dirname = (Get-Item $_).Basename;New-Item -Force -ItemType directory -Path $env:AZ_BATCH_NODE_ROOT_DIR\applications\$dirname;Expand-Archive -Path $_ -DestinationPath $env:AZ_BATCH_NODE_ROOT_DIR\applications\$dirname -force}'
$params = @{
            "startTask" = @{
                "commandLine" = $starTask
                "resourceFiles" = $resourceFiles
            }
}

Invoke-RestMethod -UseBasicParsing -Uri ($uri + "?api-version=2019-08-01.10.0") -Method PATCH -Body ($params | convertTo-json -depth 10) -Headers @{ Authorization = ("bearer " + $access); "Content-Type" = "application/json; odata=minimalmetadata"}
