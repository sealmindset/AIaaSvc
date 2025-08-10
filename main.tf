terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.109" # latest as of Aug-2025
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

module "org_guardrails" {
  source            = "./modules/org_guardrails"
  mg_name           = var.mg_name           # e.g. "mg-ai"
  allowed_locations = var.allowed_locations # e.g. ["eastus2","centralus"]
  tags              = var.tags
}

module "network" {
  source              = "./modules/network"
  location            = var.location
  hub_address_space   = ["10.0.0.0/20"]
  spoke_address_space = ["10.1.0.0/22"]
}

module "ai_service" {
  source   = "./modules/ai_service"
  location = var.location

  resource_group_name = module.network.spoke_rg_name
  vnet_id             = module.network.spoke_vnet_id
  subnets             = module.network.spoke_subnets
  enable_cmk          = var.enable_cmk
  key_vault_key_id    = var.key_vault_key_id
  tags                = var.tags
}

module "api_gateway" {
  source            = "./modules/api_gateway"
  location          = var.location
  rg_name           = module.network.spoke_rg_name
  vnet_id           = module.network.spoke_vnet_id
  subnet_id         = module.network.spoke_subnets["gateway"]
  kv_id             = module.network.kv_id
  openai_account_id = module.ai_service.openai_account_id
  openai_endpoint   = module.ai_service.openai_endpoint
}

module "observability" {
  source              = "./modules/observability"
  location            = var.location
  resource_group_name = module.network.hub_rg_name # <- now passes the name
  resources_to_monitor = [
    module.ai_service.openai_account_id,
    module.api_gateway.apim_id,
    module.network.kv_id,
    module.network.spoke_vnet_id
  ]
  tags = var.tags
}

# Placeholder for Defender for Cloud (no enablement/subscription in lab)
module "defender" {
  source = "./modules/defender"
}

