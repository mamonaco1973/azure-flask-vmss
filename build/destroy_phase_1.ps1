Write-Host "NOTE: Deleting the VMSS."
Set-Location "02-packer"

# Azure login using service principal
az login --service-principal --username $Env:ARM_CLIENT_ID --password $Env:ARM_CLIENT_SECRET --tenant $Env:ARM_TENANT_ID | Out-Null

# Fetch the latest image name
$image_name = az image list --resource-group flask-vmss-rg --query "[?starts_with(name, 'Flask_Packer_Image')]|sort_by(@, &name)[-1].name" --output tsv

Write-Host "NOTE: Using the latest image ($image_name) in flask-app-vmss"

# Check if image_name is empty
if (-not $image_name) {
    Write-Error "ERROR: No image with the prefix 'Flask_Packer_Image' was found in the resource group 'flask-vmss-rg'. Exiting."
    exit 1
}

terraform init
terraform destroy -var="image_name=$image_name" -auto-approve
Set-Location ..
