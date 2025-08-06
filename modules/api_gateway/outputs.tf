output "apim_id" {
  description = "Resource ID of the API Management instance"
  value       = azurerm_api_management.apim.id
}

output "gateway_url" {
  description = "Gateway URL for internal API access"
  value       = azurerm_api_management.apim.gateway_url
}
