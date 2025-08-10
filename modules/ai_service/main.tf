resource "azurerm_cognitive_account" "openai" {
  identity {
    type = "SystemAssigned"
  }
  name                = "cogai-${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "OpenAI"
  sku_name            = "S0"
  tags                = var.tags
  # Optional CMK encryption via Key Vault
  dynamic "customer_managed_key" {
    for_each = var.enable_cmk ? [1] : []
    content {
      key_vault_key_id = var.key_vault_key_id
    }
  }
}
