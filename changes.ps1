param(
    [string] $resourceGroupName
)
$azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
  
$currentAzureContext = Get-AzContext
$profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azProfile)
$token = $profileClient.AcquireAccessToken($currentAzureContext.Tenant.TenantId)

$today = Get-Date -Format "yyyy-MM-ddTHH:MM:00.000Z"
$yesterday = Get-Date (Get-Date).AddDays(-1) -format "yyyy-MM-ddTHH:MM:00.000Z"
$resources = Get-AzResource -resourceGroupName $resourceGroupName

foreach($resource in $resources)
{
    $resourceId = $resource.resourceId
    $resourceName = $resource.name
    Write-Host "Treating the resource $resourceName"
    $params = @{"resourceId"=$resourceId;
                "interval" = @{
                                "start"=$yesterday;
                                "end"=$today;
                            }
                }

    $response = Invoke-WebRequest -useBasicParsing -Uri https://management.azure.com/providers/Microsoft.ResourceGraph/resourceChanges?api-version=2018-09-01-preview -Method POST -Body ($params | convertTo-json) -Headers @{ Authorization = ("Bearer " + $token.AccessToken)
                    "Content-Type" = "application/json" }
    $changes = ($response.content | ConvertFrom-Json).changes
    if($changes)
    {
        Write-Host "$resourceName has been changed"
    }
}
