resource "azurerm_resource_group" "sandbox" {
  name     = "rg-apim-sandbox-${substr(uuid(),0,4)}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_api_management" "sandbox" {
  name                = "apim-sandbox-${substr(uuid(),0,6)}"
  location            = azurerm_resource_group.sandbox.location
  resource_group_name = azurerm_resource_group.sandbox.name
  publisher_name      = "Sandbox"
  publisher_email     = "sandbox@example.com"
  sku_name            = "Developer_1"
  tags                = var.tags
}

resource "azurerm_api_management_identity_provider" "oauth2" {
  name                = "oauth2"
  resource_group_name = azurerm_resource_group.sandbox.name
  api_management_name = azurerm_api_management.sandbox.name
  client_id           = var.oauth_client_id
  client_secret       = azurerm_key_vault_secret.oauth2.value
  authorization_url   = var.oauth_authorization_url
  token_url           = var.oauth_token_url
  scopes              = "openid profile email"
  grant_type          = "authorization_code"
  identity_provider   = "GenericOauth2"
}

resource "azurerm_api_management_product" "sandbox" {
  product_id          = "sandbox-product"
  api_management_name = azurerm_api_management.sandbox.name
  resource_group_name = azurerm_resource_group.sandbox.name
  display_name        = "Sandbox Product"
  approval_required   = false
  subscriptions_limit = 100
  state               = "published"
  tags                = var.tags
}

resource "azurerm_api_management_subscription" "sandbox" {
  name                = "sandbox-sub"
  api_management_name = azurerm_api_management.sandbox.name
  resource_group_name = azurerm_resource_group.sandbox.name
  product_id          = azurerm_api_management_product.sandbox.product_id
  display_name        = "Sandbox Subscription"
  state               = "active"
}
