#!/bin/bash

echo "NOTE: Deleting the VMSS."
cd 02-packer

az login --service-principal --username $ARM_CLIENT_ID --password $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID > /dev/null
image_name=$(az image list --resource-group flask-vmss-rg --query "[?starts_with(name, 'Flask_Packer_Image')]|sort_by(@, &name)[-1].name" --output tsv)

echo "NOTE: Using the latest image ($image_name) in flask-app-vmss"

# Check if image_name is empty and exit with error if no image is found
if [ -z "$image_name" ]; then
  echo "ERROR: No image with the prefix 'Flask_Packer_Image' was found in the resource group 'flask-vmss-rg'. Exiting."
  exit 1
fi

terraform init
terraform destroy -var="image_name=$image_name" -auto-approve
cd ..
