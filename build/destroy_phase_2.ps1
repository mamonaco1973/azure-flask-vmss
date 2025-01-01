$RESOURCE_GROUP = "flask-vmss-rg"

Write-Host "NOTE: Fetching images in resource group: $RESOURCE_GROUP..."
az login --service-principal --username $Env:ARM_CLIENT_ID --password $Env:ARM_CLIENT_SECRET --tenant $Env:ARM_TENANT_ID | Out-Null

$images = az image list --resource-group $RESOURCE_GROUP --query "[].{Name:name}" -o tsv

if (-not $images) {
    Write-Host "WARNING: No images found in the resource group $RESOURCE_GROUP."
    exit 0
}

Write-Host "NOTE: Deleting images in resource group: $RESOURCE_GROUP..."
foreach ($image in $images) {
    Write-Host "NOTE: Deleting image: $image"
    az image delete --resource-group $RESOURCE_GROUP --name $image
    if ($?) {
        Write-Host "NOTE: Deleted image: $image"
    } else {
        Write-Warning "Failed to delete image: $image"
    }
}

Write-Host "NOTE: All images in the resource group $RESOURCE_GROUP have been processed."
