resource "azurerm_api_management" "apim" {
  name                = "apim-ai-internal"
  location            = var.location
  resource_group_name = var.rg_name
  publisher_name      = "IT"
  publisher_email     = "it@example.com"
  sku_name            = "Premium_1"

  virtual_network_type = "Internal"
  virtual_network_configuration {
    subnet_id = var.subnet_id
  }

  identity {
    type = "SystemAssigned"
  }
}

# API definition - proxy to Azure OpenAI private endpoint.
resource "azurerm_api_management_api" "openai_proxy" {
  name                = "openai-internal"
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = var.rg_name
  revision            = "1"
  display_name        = "Internal OpenAI"
  path                = "v1"
  protocols           = ["https"]
  service_url         = "${var.openai_endpoint}/openai/deployments/gpt4o"
  import {
    content_format = "openapi"
    content_value  = file("${path.module}/openai-swagger.json")
  }
}

# Subscription (token) for each internal application
resource "azurerm_api_management_subscription" "team_token" {
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = var.rg_name
  display_name        = "internal-ai-consumer"
  state               = "active"
  allow_tracing       = false
}

output "internal_api_base_url" {
  value = azurerm_api_management.apim.gateway_url
}
