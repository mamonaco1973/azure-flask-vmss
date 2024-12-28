packer {
  required_plugins {
    azure = {
      source   = "github.com/hashicorp/azure"
      version  = "~> 2"
    }
  }
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

# https://github.com/DevOpsCnS/Packer/blob/main/azure_ubuntu_image/az_ubuntu-apache2.pkr.hcl
# az cosmosdb list --resource-group flask-vmss-rg --query "[?starts_with(name, 'candidates')].{name:name, url:documentEndpoint}" --output table

variable "COSMOS_ENDPOINT" {
  description = "The endpoint for the Cosmos DB"
  type        = string
  default     = "https://candidates-e4dee2.documents.azure.com:443/"
}

variable "client_id" {
  description = "Azure Client ID"
  type        = string
}

variable "client_secret" {
  description = "Azure Client Secret"
  type        = string
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

source "azure-arm" "packer_build_image" {

  client_id       = var.client_id
  client_secret   = var.client_secret
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id

  image_offer                       = "ubuntu-24_04-lts"
  image_publisher                   = "canonical"
  image_sku                         = "server"
  location                          = "Central US"
  vm_size                           = "Standard_B1s"
  os_type                           = "Linux"

  managed_image_name                = "Flask_Packer_Image-${local.timestamp}"
  managed_image_resource_group_name = "flask-vmss-rg"
}

build {
  sources = ["source.azure-arm.packer_build_image"]

  # Provisioner to run shell commands during the build
  provisioner "shell" {
    inline = [
      "sudo mkdir -p /flask",      # Create the /flask directory
      "sudo chmod 777 /flask"      # Set permissions to allow access
    ]
  }

  # Provisioner to copy local scripts to the instance
  provisioner "file" {
    source      = "./scripts/"    # Path to the local scripts directory
    destination = "/flask/"       # Destination directory on the instance
  }

  # Provisioner to run a shell script during the build and pass the COSMOS_ENDPOINT variable
  provisioner "shell" {
    script = "./install.sh"       # Path to the install script
    environment_vars = [
      "COSMOS_ENDPOINT=${var.COSMOS_ENDPOINT}"  # Pass the COSMOS_ENDPOINT as an environment variable
    ]
  }
}
