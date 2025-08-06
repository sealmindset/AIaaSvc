############################################
# Grant OpenAI managed identity CMK access #
############################################

resource "azurerm_role_assignment" "openai_kv_crypto" {
  scope                = var.key_vault_key_id
  role_definition_name = "Key Vault Crypto User"
  principal_id         = azurerm_cognitive_account.openai.identity[0].principal_id
}
