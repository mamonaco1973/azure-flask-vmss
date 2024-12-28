# Configure the Azure Provider
provider "azurerm" {
  features {} # Enables all optional features in the Azure provider
}

# Retrieve the Azure subscription details
data "azurerm_subscription" "primary" {}

# Retrieve the Azure client configuration for authentication
data "azurerm_client_config" "current" {}

# Define the resource group for the deployment
resource "azurerm_resource_group" "flask-vmss" {
  name     = "flask-vmss-rg"       # Name of the resource group
  location = "Central US"          # Azure region for the resource group
}

# Create an SSH public key in Azure
# NOTE: Avoid including the private key in your project for security reasons.
# The private key is included here only for learning purposes as shown in the associated video.
resource "azurerm_ssh_public_key" "flask_vmss_key" {
  name                = "flask-vmss-key"                           # Name of the SSH key resource
  resource_group_name = azurerm_resource_group.flask-vmss.name     # Resource group where the key will be created
  location            = azurerm_resource_group.flask-vmss.location # Location of the resource group
  public_key          = file("./keys/VM_key_public")               # Path to the public key file on your local machine
}
