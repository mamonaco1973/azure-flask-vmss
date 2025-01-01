Write-Host "NOTE: Deleting the infrastructure."
Set-Location "01-infrastructure"

terraform init
terraform destroy -auto-approve

Set-Location ..
