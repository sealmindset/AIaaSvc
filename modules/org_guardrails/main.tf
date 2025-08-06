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

########################################
# 1. Create / reference Management Group
########################################
resource "azurerm_management_group" "org" {
  name = var.mg_name
  # If the MG already exists, leave `display_name` and `parent_management_group_id`
  # unset so the provider does a lookup instead of trying to recreate it.
  # Otherwise you can uncomment these two:
  # display_name              = var.mg_name
  # parent_management_group_id = "00000000-0000-0000-0000-000000000000" # Tenant root
}

########################################################
# 2. Built-in Azure Policy — “Allowed Locations” example
########################################################
data "azurerm_policy_definition" "allowed_locations" {
  display_name = "Allowed locations"
}

resource "azurerm_management_group_policy_assignment" "allowed_locations" {
  name                 = "allowed-locations"
  management_group_id  = azurerm_management_group.org.id
  policy_definition_id = data.azurerm_policy_definition.allowed_locations.id

  parameters = jsonencode({
    listOfAllowedLocations = {
      value = var.allowed_locations
    }
  })

  metadata = <<METADATA
    {
      "category": "General",
      "assignedBy": "Terraform – org_guardrails module"
    }
METADATA
}

##########################################################
# 3. (Optional) Tag policy to require common set of tags  #
##########################################################
data "azurerm_policy_definition" "require_tags" {
  display_name = "Require a tag on resources"
}

resource "azurerm_management_group_policy_assignment" "require_tags" {
  name                 = "require-common-tags"
  management_group_id  = azurerm_management_group.org.id
  policy_definition_id = data.azurerm_policy_definition.require_tags.id

  parameters = jsonencode({
    tagName = { value = "environment" }
  })
  metadata = <<METADATA
    { "category": "Tags", "assignedBy": "Terraform – org_guardrails module" }
METADATA
  # Scope-level tags aren’t created by the assignment itself,
  # but we surface them here so they’re easy to discover.
  lifecycle {
    ignore_changes = [parameters]
  }
}
