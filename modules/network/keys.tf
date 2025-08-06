#################################
# Customer-managed Key for KV   #
#################################

resource "azurerm_key_vault_key" "cmk" {
  name         = "openai-cmk"
  key_vault_id = azurerm_key_vault.kv.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts     = ["decrypt", "encrypt", "wrapKey", "unwrapKey"]
}

output "kv_key_id" {
  description = "ID of the CMK to be used by OpenAI"
  value       = azurerm_key_vault_key.cmk.id
}
