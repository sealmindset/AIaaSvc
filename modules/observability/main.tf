terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.109"
    }
  }
}

provider "azurerm" {
  features {}
}

###############################
# 1. Log Analytics workspace  #
###############################
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-ai-${substr(uuid(), 0, 6)}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 365
  tags                = var.tags
}

#################################
# 2. Archival Storage account   #
#################################
resource "azurerm_storage_account" "diag" {
  name                     = "stdiag${substr(uuid(), 0, 8)}"
  location                 = var.location
  resource_group_name      = var.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "GRS"

  infrastructure_encryption_enabled = true
  min_tls_version                   = "TLS1_2"
  # Enable shared-key access so Terraform can read queue properties
  shared_access_key_enabled         = true

  # Disallow public access to blobs and queues
  allow_nested_items_to_be_public = false

  # Enable logging for queue service
  queue_properties {
    logging {
      delete  = true
      read    = true
      write   = true
      version = "1.0"
    }
  }

  tags = var.tags
}

########################################
# 3. Diagnostic Settings per resource  #
########################################
resource "azurerm_monitor_diagnostic_setting" "diag" {
  # Convert list -> map with index keys so keys are known at plan-time
  for_each           = { for idx, id in var.resources_to_monitor : idx => id }
  name               = "diag"
  target_resource_id = each.value

  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  storage_account_id         = azurerm_storage_account.diag.id

  log {
    category = "AllLogs"
    enabled  = true
    retention_policy {
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true
    retention_policy {
      enabled = false
    }
  }
}
