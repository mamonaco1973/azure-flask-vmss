# Cosmos DB Account Configuration
resource "azurerm_cosmosdb_account" "candidate_account" {
  name                = "candidates-${substr(data.azurerm_client_config.current.subscription_id, 0, 8)}" 
  # Unique Cosmos DB account name using a substring of the subscription ID
  location            = azurerm_resource_group.flask-vmss.location # Azure region
  resource_group_name = azurerm_resource_group.flask-vmss.name     # Resource group for the Cosmos DB account
  offer_type          = "Standard"                                 # Pricing tier for the Cosmos DB account
  kind                = "GlobalDocumentDB"                         # Cosmos DB account type

  # Define the consistency policy for the Cosmos DB account
  consistency_policy {
    consistency_level = "Session" # Ensures session consistency for operations
  }

  # Configure geo-replication for high availability
  geo_location {
    location          = azurerm_resource_group.flask-vmss.location # Primary region
    failover_priority = 0                                          # Highest priority for this region
  }

  # Enable serverless mode for the Cosmos DB account
  capabilities {
    name = "EnableServerless"
  }
}

# Cosmos DB SQL Database
resource "azurerm_cosmosdb_sql_database" "candidate_database" {
  name                = "CandidateDatabase"                             # Name of the SQL database
  resource_group_name = azurerm_resource_group.flask-vmss.name          # Resource group for the database
  account_name        = azurerm_cosmosdb_account.candidate_account.name # Parent Cosmos DB account name
}

# Cosmos DB SQL Container Configuration
resource "azurerm_cosmosdb_sql_container" "candidate_container" {
  name                = "Candidates"                                          # Name of the table
  resource_group_name = azurerm_resource_group.flask-vmss.name                # Resource group for the table
  account_name        = azurerm_cosmosdb_account.candidate_account.name       # Parent Cosmos DB account name
  database_name       = azurerm_cosmosdb_sql_database.candidate_database.name # Parent database name

  # Define the partition key for the container

  partition_key_paths = ["/CandidateName"] # Partition key path for optimized data distribution

  # Configure the indexing policy for the container
  indexing_policy {
    indexing_mode = "consistent" # Ensure consistent indexing for all operations

    included_path {
      path = "/*" # Include all paths in the indexing policy
    }

    excluded_path {
      path = "/_etag/?" # Exclude the `_etag` path from indexing
    }
  }
}
