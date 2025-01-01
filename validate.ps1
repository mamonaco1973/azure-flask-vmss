# Variables
$ResourceGroup = "flask-vmss-rg"
$AppGatewayName = "flask-app-gateway"  # Replace with your App Gateway name
$CheckInterval = 30  # Time to wait (in seconds) between checks
$MaxRetries = 20     # Maximum number of retries


# Wait for healthy backend servers
Write-Host "NOTE: Waiting for at least one healthy backend server..."
for ($i = 1; $i -le $MaxRetries; $i++) {
    $HealthyServers = az network application-gateway show-backend-health `
                            --resource-group $ResourceGroup `
                            --name $AppGatewayName `
                            --query "backendAddressPools[].backendHttpSettingsCollection[].servers[?health == 'Healthy']" `
                            -o tsv

    if ($HealthyServers) {
        Write-Host "NOTE: At least one healthy backend server found!"
        
        $DnsName = az network public-ip show `
            --name flask-app-gateway-public-ip `
            --resource-group $ResourceGroup `
            --query "dnsSettings.fqdn" `
            --output tsv
        
        Write-Host "NOTE: Health check endpoint is http://$DnsName/gtg?details=true"
        
        .\build\test_candidates.ps1 $DnsName 
        
        exit 0
    }

    Write-Host "NOTE: No healthy backend servers yet. Retrying in $CheckInterval seconds..."
    Start-Sleep -Seconds $CheckInterval
}

Write-Host "ERROR: Timeout reached. No healthy backend servers found."
exit 1
