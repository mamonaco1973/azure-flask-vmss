# Define the AzureRM provider
provider "azurerm" {
  features {}                                         # Enable all default features
}

# Retrieve subscription information
data "azurerm_subscription" "primary" {}

# Retrieve current client configuration
data "azurerm_client_config" "current" {}

# Define a variable for the custom Azure image name
variable "image_name" {
  description = "The name of the custom Azure image"  # Description of the variable
  type        = string                                # Variable type
}

variable "instances" {
   description = "The number of instances to start in the VMSS."
   type        = number
   default     = 0
}

# Retrieve the resource group details
data "azurerm_resource_group" "flask_vmss_rg" {
  name = "flask-vmss-rg"                              # Resource group name
}

# Retrieve the latest Azure image from the resource group
data "azurerm_image" "flask_packer_image" {
  name                = var.image_name                                 # Name of the custom image
  resource_group_name = data.azurerm_resource_group.flask_vmss_rg.name # Resource group for the image
}

# Retrieve the application gateway details
data "azurerm_application_gateway" "flask_app_gateway" {
  name                = "flask-app-gateway"                            # Application gateway name
  resource_group_name = data.azurerm_resource_group.flask_vmss_rg.name # Resource group name
}

# Retrieve the virtual network details
data "azurerm_virtual_network" "flask_app_vnet" {
  name                = "flask-app-vnet"                               # Virtual network name
  resource_group_name = data.azurerm_resource_group.flask_vmss_rg.name # Resource group name
}

# Retrieve the subnet details
data "azurerm_subnet" "flask_app_subnet" {
  name                 = "flask-app-subnet"                               # Subnet name
  virtual_network_name = data.azurerm_virtual_network.flask_app_vnet.name # Parent VNet name
  resource_group_name  = data.azurerm_resource_group.flask_vmss_rg.name   # Resource group name
}

# Retrieve the SSH public key details
data "azurerm_ssh_public_key" "flask_vmss_key" {
  name                = "flask-vmss-key"                               # SSH key name
  resource_group_name = data.azurerm_resource_group.flask_vmss_rg.name # Resource group name
}

# Retrieve the Cosmos DB account details
data "azurerm_cosmosdb_account" "candidate_account" {
  name                = "candidates-${substr(data.azurerm_client_config.current.subscription_id, 0, 8)}" # Cosmos DB account name
  resource_group_name = data.azurerm_resource_group.flask_vmss_rg.name                                   # Resource group name
}

# Define the Linux VM scale set
resource "azurerm_linux_virtual_machine_scale_set" "flask_vmss" {
  name                = "flask-vmss"                                       # VM scale set name
  location            = data.azurerm_resource_group.flask_vmss_rg.location # Azure region
  resource_group_name = data.azurerm_resource_group.flask_vmss_rg.name     # Resource group name
  sku                 = "Standard_B1s"                                     # VM size
  instances           = 0                                                  # Number of instances
  admin_username      = "azureuser"                                        # Admin username
  source_image_id     = data.azurerm_image.flask_packer_image.id           # Source image ID
  zones               = ["1", "2"]                                         # Availability zones

  admin_ssh_key {
    username   = "azureuser"                                              # Admin username for SSH
    public_key = data.azurerm_ssh_public_key.flask_vmss_key.public_key    # Public SSH key
  }

  os_disk {
    caching              = "ReadWrite"               # OS disk caching option
    storage_account_type = "Standard_LRS"            # Storage account type
  }

  network_interface {
    name    = "flask-vmss-nic"                       # NIC name
    primary = true                                   # Primary NIC

    ip_configuration {
      name      = "internal"                                                          # IP configuration name
      subnet_id = data.azurerm_subnet.flask_app_subnet.id                             # Subnet ID
      application_gateway_backend_address_pool_ids = [
        data.azurerm_application_gateway.flask_app_gateway.backend_address_pool[0].id # Backend pool ID
      ]
    }
  }

  computer_name_prefix = "flask"                     # Computer name prefix
  upgrade_mode         = "Automatic"                 # Upgrade mode

  automatic_instance_repair {
    enabled      = true                              # Enable automatic instance repair
    grace_period = "PT10M"                           # Grace period for repair
  }

  extension {
    name                 = "HealthExtension"           # Extension name
    publisher            = "Microsoft.ManagedServices" # Publisher
    type                 = "ApplicationHealthLinux"    # Extension type
    type_handler_version = "1.0"                       # Extension version

    settings = jsonencode({
      protocol    = "http",                            # Protocol used by the health extension
      port        = 8000,                              # Port for health checks
      requestPath = "/gtg"                             # Request path for health checks
    })
  }

  identity {
    type = "SystemAssigned"                            # System-assigned managed identity
  }
}

# Define autoscale settings for the VM scale set
resource "azurerm_monitor_autoscale_setting" "flask_vmss_autoscale" {
  name                = "flask-vmss-autoscale"                                # Autoscale setting name
  resource_group_name = data.azurerm_resource_group.flask_vmss_rg.name        # Resource group name
  location            = data.azurerm_resource_group.flask_vmss_rg.location    # Azure region
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.flask_vmss.id # Target resource

  profile {
    name = "default"                                 # Profile name

    capacity {
      minimum = var.instances                        # Minimum instance count
      default = var.instances                        # Default instance count
      maximum = "4"                                  # Maximum instance count
    }

    # Scale up rule
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"                                      # Metric name
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.flask_vmss.id # Metric resource ID
        operator           = "GreaterThan"                                         # Comparison operator
        statistic          = "Average"                                             # Statistic used
        threshold          = 60                                                    # Threshold for scaling
        time_grain         = "PT1M"                                                # Granularity
        time_window        = "PT1M"                                                # Time window
        time_aggregation   = "Average"                                             # Aggregation type
      }

      scale_action {
        direction = "Increase"                     # Scale direction
        type      = "ChangeCount"                  # Scale type
        value     = "1"                            # Change count
        cooldown  = "PT1M"                         # Cooldown period
      }
    }

    # Scale down rule
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"                                      # Metric name
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.flask_vmss.id # Metric resource ID
        operator           = "LessThan"                                            # Comparison operator
        statistic          = "Average"                                             # Statistic used
        threshold          = 60                                                    # Threshold for scaling
        time_grain         = "PT5M"                                                # Granularity
        time_window        = "PT5M"                                                # Time window
        time_aggregation   = "Average"                                             # Aggregation type
      }

      scale_action {
        direction = "Decrease"                    # Scale direction
        type      = "ChangeCount"                 # Scale type
        value     = "1"                           # Change count
        cooldown  = "PT1M"                        # Cooldown period
      }
    }
  }
}

# Define a custom Cosmos DB role
resource "azurerm_cosmosdb_sql_role_definition" "custom_cosmos_role" {
  name                = "CustomCosmoDBRole"                                  # Role name
  resource_group_name = data.azurerm_resource_group.flask_vmss_rg.name       # Resource group name
  account_name        = data.azurerm_cosmosdb_account.candidate_account.name # Cosmos DB account name
  type                = "CustomRole"                                         # Role type
  assignable_scopes   = [data.azurerm_cosmosdb_account.candidate_account.id] # Assignable scopes

  permissions {
    data_actions = [                                 # Data actions allowed
      "Microsoft.DocumentDB/databaseAccounts/readMetadata",
      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*",
      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*"
    ]
  }
}

# Assign the custom Cosmos DB role to the VMSS
resource "azurerm_cosmosdb_sql_role_assignment" "vmss_cosmosdb_role" {
  principal_id        = azurerm_linux_virtual_machine_scale_set.flask_vmss.identity[0].principal_id # Principal ID
  role_definition_id  = azurerm_cosmosdb_sql_role_definition.custom_cosmos_role.id                  # Role definition ID
  scope               = data.azurerm_cosmosdb_account.candidate_account.id                          # Scope
  account_name        = data.azurerm_cosmosdb_account.candidate_account.name                        # Cosmos DB account name
  resource_group_name = data.azurerm_resource_group.flask_vmss_rg.name                              # Resource group name
}
