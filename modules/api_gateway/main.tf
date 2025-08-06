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

# Policy applying MSI and subscription validation
resource "azurerm_api_management_api_policy" "openai_policy" {
  api_name            = azurerm_api_management_api.openai_proxy.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = var.rg_name
  xml_content         = file("${path.module}/policies/openai.xml")
}

# Subscription (token) for each internal application
resource "azurerm_api_management_subscription" "team_token" {
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = var.rg_name
  display_name        = "internal-ai-consumer"
  state               = "active"
  allow_tracing       = false
}

# Role assignment: APIM MSI ➜ Azure OpenAI
resource "azurerm_role_assignment" "apim_openai_user" {
  scope                = var.openai_account_id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_api_management.apim.identity[0].principal_id
  tags                 = var.tags
}

# Product for self-service subscription keys
resource "azurerm_api_management_product" "openai_product" {
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = var.rg_name
  product_id          = "openai"
  display_name        = "Internal OpenAI"
  approval_required   = true
  subscriptions_limit = -1
  published           = true
  tags                = var.tags
}

resource "azurerm_api_management_product_api" "openai_link" {
  api_name            = azurerm_api_management_api.openai_proxy.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = var.rg_name
  product_id          = azurerm_api_management_product.openai_product.product_id
}

# Optional seed subscriptions
resource "azurerm_api_management_subscription" "seed" {
  for_each            = toset(var.initial_user_object_ids)
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = var.rg_name
  product_id          = azurerm_api_management_product.openai_product.product_id
  display_name        = "seed-sub-${each.value}"
  owner_id            = format("/users/%s", each.value)
  state               = "active"
  tags                = var.tags
}

output "internal_api_base_url" {
  value = azurerm_api_management.apim.gateway_url
}
