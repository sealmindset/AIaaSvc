resource "random_string" "kv_suffix" {
  length  = 6
  upper   = false
  numeric  = true
  special = false
}

resource "azurerm_key_vault" "sandbox" {
  name                = "kv-sandbox-${random_string.kv_suffix.result}"
  location            = azurerm_resource_group.sandbox.location
  resource_group_name = azurerm_resource_group.sandbox.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  purge_protection_enabled = true
  soft_delete_enabled      = true

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = ["Get", "Set", "List"]
  }

  network_acls {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  tags = var.tags
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault_secret" "oauth2" {
  name         = "oauth-client-secret"
  value        = var.oauth_client_secret
  key_vault_id = azurerm_key_vault.sandbox.id
}
