output "openai_account_id" {
  description = "ID of the Azure Cognitive Service account (OpenAI)"
  value       = azurerm_cognitive_account.openai.id
}

output "openai_endpoint" {
  description = "Endpoint URL of the OpenAI cognitive account"
  value       = azurerm_cognitive_account.openai.endpoint
}
