
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0"
}

provider "azurerm" {
  features {}
}

variable "oauth_client_id" {
  type        = string
  description = "OAuth2 client ID"
}

variable "oauth_client_secret" {
  type        = string
  description = "OAuth2 client secret"
  sensitive   = true
}

variable "oauth_authorization_url" {
  type        = string
  description = "OAuth2 authorization URL"
}

variable "oauth_token_url" {
  type        = string
  description = "OAuth2 token URL"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-apim-sandbox"
  location = "Central US"
}

resource "azurerm_api_management" "apim" {
  name                = "apim-sandbox"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = "Seal Mindset"
  publisher_email     = "sealmindset@gmail.com"
  sku_name            = "Developer_1"
}

resource "azurerm_api_management_portal" "portal" {
  api_management_id = azurerm_api_management.apim.id
  enabled           = true
}

resource "azurerm_api_management_identity_provider" "oauth2" {
  name                = "oauth2"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  client_id           = var.oauth_client_id
  client_secret       = var.oauth_client_secret
  authorization_url   = var.oauth_authorization_url
  token_url           = var.oauth_token_url
  scopes              = "openid profile email"
  grant_type          = "authorization_code"
  identity_provider   = "GenericOauth2"
}

resource "azurerm_api_management_product" "sandbox_product" {
  product_id          = "sandbox-product"
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Sandbox Product"
  approval_required   = false
  subscriptions_limit = 100
  state               = "published"
}

resource "azurerm_api_management_subscription" "sandbox_subscription" {
  name                = "sandbox-subscription"
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  product_id          = azurerm_api_management_product.sandbox_product.product_id
  display_name        = "Sandbox Subscription"
  allow_tracing       = true
  state               = "active"
}

output "apim_name" {
  value = azurerm_api_management.apim.name
}

output "sandbox_product_id" {
  value = azurerm_api_management_product.sandbox_product.product_id
}

output "subscription_key" {
  value     = azurerm_api_management_subscription.sandbox_subscription.primary_key
  sensitive = true
}
