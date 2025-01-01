#!/bin/bash

# Second phase - Run the packer build to build the application after we have the resource group

cd 02-packer
echo "NOTE: Phase 2 Building Image with packer."

az login --service-principal --username $ARM_CLIENT_ID --password $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID > /dev/null

# Fetch the COSMOS_ENDPOINT dynamically
COSMOS_ENDPOINT=$(az cosmosdb list --resource-group flask-vmss-rg \
    --query "[?starts_with(name, 'candidates')].{url:documentEndpoint}[0].url" \
    --output tsv)

# Check if the COSMOS_ENDPOINT was successfully fetched
if [ -z "$COSMOS_ENDPOINT" ]; then
    echo "ERROR: Failed to fetch the Cosmos DB endpoint."
    exit 1
fi

# Use the COSMOS_ENDPOINT
echo "NOTE: COSMOS_ENDPOINT is set to: $COSMOS_ENDPOINT"

packer init .

packer build \
  -var="client_id=$ARM_CLIENT_ID" \
  -var="client_secret=$ARM_CLIENT_SECRET" \
  -var="subscription_id=$ARM_SUBSCRIPTION_ID" \
  -var="tenant_id=$ARM_TENANT_ID" \
  -var="COSMOS_ENDPOINT=$COSMOS_ENDPOINT" \
  flask_image.pkr.hcl

cd ..
