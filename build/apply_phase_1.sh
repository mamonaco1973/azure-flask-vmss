#!/bin/bash

# First phase - Build all the core infrastructure

cd 01-infrastructure
echo "NOTE: Building infrastructure phase 1."
terraform init
terraform apply -auto-approve
cd ..