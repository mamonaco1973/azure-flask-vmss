#!/bin/bash

echo "NOTE: Deleting the infrastructure."
cd 01-infrastructure

terraform init
terraform destroy -auto-approve

cd ..
