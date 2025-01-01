Set-Location "02-packer"
Write-Host "NOTE: Phase 2 Building Image with packer."

az login --service-principal --username $Env:ARM_CLIENT_ID --password $Env:ARM_CLIENT_SECRET --tenant $Env:ARM_TENANT_ID | Out-Null

# Fetch the Cosmos DB endpoint
$COSMOS_ENDPOINT = az cosmosdb list --resource-group flask-vmss-rg `
    --query "[?starts_with(name, 'candidates')].{url:documentEndpoint}[0].url" --output tsv

if (-not $COSMOS_ENDPOINT) {
    Write-Error "ERROR: Failed to fetch the Cosmos DB endpoint."
    exit 1
}

Write-Host "NOTE: COSMOS_ENDPOINT is set to: $COSMOS_ENDPOINT"

packer init .

packer build `
    -var="client_id=$Env:ARM_CLIENT_ID" `
    -var="client_secret=$Env:ARM_CLIENT_SECRET" `
    -var="subscription_id=$Env:ARM_SUBSCRIPTION_ID" `
    -var="tenant_id=$Env:ARM_TENANT_ID" `
    -var="COSMOS_ENDPOINT=$COSMOS_ENDPOINT" `
    flask_image.pkr.hcl

Set-Location ..
