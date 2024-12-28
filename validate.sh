#!/bin/bash

# Variables
RESOURCE_GROUP="flask-vmss-rg"
APP_GATEWAY_NAME="flask-app-gateway"  # Replace with your App Gateway name
CHECK_INTERVAL=30  # Time to wait (in seconds) between checks
MAX_RETRIES=20     # Maximum number of retries

# Function to check backend health
check_backend_health() {
    az network application-gateway show-backend-health \
        --resource-group "$RESOURCE_GROUP" \
        --name "$APP_GATEWAY_NAME" \
        --query "backendAddressPools[].backendHttpSettingsCollection[].servers[?health == 'Healthy']" \
        -o tsv
}

# Wait for healthy backend servers
echo "NOTE: Waiting for at least one healthy backend server..."
for ((i = 1; i <= MAX_RETRIES; i++)); do
    HEALTHY_SERVERS=$(check_backend_health)

    if [[ -n "$HEALTHY_SERVERS" ]]; then
        echo "NOTE: At least one healthy backend server found!"
	
	export DNS_NAME=$(az network public-ip show \
 	    --name flask-app-gateway-public-ip \
            --resource-group $RESOURCE_GROUP \
            --query "dnsSettings.fqdn" \
            --output tsv)

	echo "NOTE: Health check endpoint is http://$DNS_NAME/gtg?details=true"
	./02-packer/scripts/test_candidates.py $DNS_NAME

        exit 0
    fi

    echo "NOTE: Retry $i/$MAX_RETRIES: No healthy backend servers yet. Retrying in $CHECK_INTERVAL seconds..."
    sleep "$CHECK_INTERVAL"
done

echo "ERROR: Timeout reached. No healthy backend servers found."
exit 1
