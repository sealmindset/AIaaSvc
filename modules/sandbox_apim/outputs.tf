output "sandbox_apim_name" {
  value = azurerm_api_management.sandbox.name
}

output "sandbox_product_id" {
  value = azurerm_api_management_product.sandbox.product_id
}

output "sandbox_subscription_primary_key" {
  value     = azurerm_api_management_subscription.sandbox.primary_key
  sensitive = true
}
