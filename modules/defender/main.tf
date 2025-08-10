terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.109"
    }
  }
}

provider "azurerm" {
  features {}
}

# Placeholder module for Microsoft Defender for Cloud integration
# Intentionally does not subscribe, create, or enable any Defender plans.
# This module exists to establish structure and future variables/outputs.
# In enterprise environments, central security usually manages Defender.

# Example (commented) resources for future use:
# resource "azurerm_security_center_subscription_pricing" "defender_storage" {
#   tier = "Standard" # DO NOT ENABLE IN THIS LAB
# }
