Write-Host "NOTE: Phase 3 build the VMSS and apply the custom image."

Set-Location "02-packer"

az login --service-principal --username $Env:ARM_CLIENT_ID --password $Env:ARM_CLIENT_SECRET --tenant $Env:ARM_TENANT_ID | Out-Null

$image_name = az image list --resource-group flask-vmss-rg `
    --query "[?starts_with(name, 'Flask_Packer_Image')]|sort_by(@, &name)[-1].name" --output tsv

Write-Host "NOTE: Using the latest image ($image_name) in flask-app-vmss"

if (-not $image_name) {
    Write-Error "No image with the prefix 'Flask_Packer_Image' was found in the resource group 'flask-vmss-rg'. Exiting."
    exit 1
}

terraform init
terraform apply -var="image_name=$image_name" -auto-approve
az vmss restart --name flask-vmss --resource-group flask-vmss-rg
terraform apply -var="image_name=$image_name" -var="instances=2" -auto-approve

Set-Location ..
