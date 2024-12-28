# Public IP for the Application Gateway
resource "azurerm_public_ip" "flask_app_gateway_public_ip" {
  name                = "flask-app-gateway-public-ip"                           # Name of the public IP
  location            = azurerm_resource_group.flask-vmss.location              # Azure region
  resource_group_name = azurerm_resource_group.flask-vmss.name                  # Resource group for the public IP
  allocation_method   = "Static"                                                # Allocation method for the public IP
  sku                 = "Standard"                                              # SKU of the public IP
  domain_name_label   = "flask-app-vmss-${substr(data.azurerm_client_config.current.subscription_id, 0, 6)}" # Unique DNS label
  zones               = ["1", "2"]                                              # Availability zones for high availability
}

# Application Gateway
resource "azurerm_application_gateway" "flask_app_gateway" {
  name                = "flask-app-gateway"                                      # Name of the application gateway
  location            = azurerm_resource_group.flask-vmss.location               # Azure region
  resource_group_name = azurerm_resource_group.flask-vmss.name                   # Resource group for the application gateway
  zones               = ["1", "2"]                                               # Availability zones for redundancy

  # SKU configuration
  sku {
    name     = "Standard_v2"                                                     # SKU name
    tier     = "Standard_v2"                                                     # Tier of the application gateway
    capacity = 1                                                                 # Instance capacity
  }

  # Gateway IP configuration
  gateway_ip_configuration {
    name      = "app-gateway-ip-config"                                          # Name of the IP configuration
    subnet_id = azurerm_subnet.app-gateway-subnet.id                             # Subnet for the application gateway
  }

  # Frontend IP configuration
  frontend_ip_configuration {
    name                 = "app-gateway-frontend"                                # Name of the frontend configuration
    public_ip_address_id = azurerm_public_ip.flask_app_gateway_public_ip.id      # Public IP associated with the gateway
  }

  # Frontend port configuration
  frontend_port {
    name = "http-port"                                                           # Name of the frontend port
    port = 80                                                                    # Port number for HTTP traffic
  }

  # Backend address pool
  backend_address_pool {
    name = "app-gateway-backend-pool"                                            # Name of the backend address pool
  }

  # Backend HTTP settings
  backend_http_settings {
    name                  = "http-settings"                                      # Name of the HTTP settings
    cookie_based_affinity = "Disabled"                                           # Cookie-based affinity disabled
    path                  = "/"                                                  # Path for requests
    port                  = 8000                                                 # Port number for backend servers
    protocol              = "Http"                                               # Protocol used
    request_timeout       = 30                                                   # Timeout for requests in seconds
    probe_name            = "custom-health-probe"                                # Health probe for backend servers
  }

  # Custom health probe
  probe {
    name                = "custom-health-probe"                                  # Name of the health probe
    protocol            = "Http"                                                 # Protocol used for the probe
    path                = "/gtg"                                                 # Health probe path
    interval            = 5                                                      # Interval between probe checks in seconds
    timeout             = 5                                                      # Timeout for probe response in seconds
    unhealthy_threshold = 1                                                      # Unhealthy threshold for marking backend as unhealthy
    host                = "127.0.0.1"                                            # Host for the probe - dummy ip address is replaced by VMSS
  }

  # HTTP listener configuration
  http_listener {
    name                           = "http-listener"                             # Name of the HTTP listener
    frontend_ip_configuration_name = "app-gateway-frontend"                      # Frontend IP configuration for the listener
    frontend_port_name             = "http-port"                                 # Frontend port name
    protocol                       = "Http"                                      # Protocol used for the listener
  }

  # Request routing rule
  request_routing_rule {
    name                       = "http-routing-rule"                            # Name of the routing rule
    rule_type                  = "Basic"                                        # Rule type
    http_listener_name         = "http-listener"                                # HTTP listener associated with the rule
    backend_address_pool_name  = "app-gateway-backend-pool"                     # Backend address pool for the rule
    backend_http_settings_name = "http-settings"                                # Backend HTTP settings for the rule
    priority                   = 1                                              # Priority of the rule
  }
}
