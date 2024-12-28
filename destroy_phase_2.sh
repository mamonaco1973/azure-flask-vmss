#!/bin/bash

RESOURCE_GROUP="flask-vmss-rg"

# List all images in the resource group
echo "NOTE: Fetching images in resource group: $RESOURCE_GROUP..."
az login --service-principal --username $ARM_CLIENT_ID --password $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID > /dev/null
images=$(az image list --resource-group "$RESOURCE_GROUP" --query "[].{Name:name}" -o tsv)

if [ -z "$images" ]; then
    echo "WARNING: No images found in the resource group $RESOURCE_GROUP."
    exit 0
fi

# Iterate through the list of images and delete them
echo "NOTE: Deleting images in resource group: $RESOURCE_GROUP..."
for image in $images; do
    echo "NOTE: Deleting image: $image"
    az image delete --resource-group "$RESOURCE_GROUP" --name "$image"
    if [ $? -eq 0 ]; then
        echo "NOTE: Deleted image: $image"
    else
        echo "WARNING: Failed to delete image: $image"
    fi
done

echo "NOTE: All images in the resource group $RESOURCE_GROUP have been processed."
