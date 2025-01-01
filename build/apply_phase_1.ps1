Set-Location "01-infrastructure"
Write-Host "NOTE: Building infrastructure phase 1."

terraform init
terraform apply -auto-approve

Set-Location ..
