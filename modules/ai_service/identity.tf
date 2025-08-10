############################################
# Grant OpenAI managed identity CMK access #
############################################

locals {
  # Derive the Key Vault resource ID from a full key ID, e.g.
  # /subscriptions/.../resourceGroups/.../providers/Microsoft.KeyVault/vaults/<vault>/keys/<key>/<version>
  # -> /subscriptions/.../resourceGroups/.../providers/Microsoft.KeyVault/vaults/<vault>
  kv_scope_from_key = var.key_vault_key_id != "" ? replace(var.key_vault_key_id, "/keys/.+$", "") : ""
}

resource "azurerm_role_assignment" "openai_kv_crypto" {
  count               = var.enable_cmk && var.key_vault_key_id != "" ? 1 : 0
  scope               = local.kv_scope_from_key
  role_definition_name = "Key Vault Crypto User"
  principal_id        = azurerm_cognitive_account.openai.identity[0].principal_id
}
