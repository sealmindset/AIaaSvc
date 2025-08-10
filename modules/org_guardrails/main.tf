terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.109"
    }
  }
}
###############################################################
# 5. Guardrails for Key Vault and Storage                      #
#    - Deny public network access                              #
###############################################################

# Deny public network access for Key Vault
resource "azurerm_policy_definition" "kv_deny_public_access" {
  name         = "kv-deny-public-network-access"
  display_name = "Key Vault should disable public network access"
  mode         = "Indexed"
  policy_type  = "Custom"
  management_group_id = azurerm_management_group.org.id

  policy_rule = jsonencode({
    if = {
      allOf = [
        { field = "type", equals = "Microsoft.KeyVault/vaults" },
        { field = "Microsoft.KeyVault/vaults/networkAcls.defaultAction", equals = "Allow" }
      ]
    }
    then = { effect = "deny" }
  })

  metadata = jsonencode({ category = "Key Vault" })
}

resource "azurerm_management_group_policy_assignment" "kv_deny_public_access" {
  name                 = "kv-deny-public-network-access"
  management_group_id  = azurerm_management_group.org.id
  policy_definition_id = azurerm_policy_definition.kv_deny_public_access.id
}

# Deny public network access for Storage Accounts
resource "azurerm_policy_definition" "storage_deny_public_access" {
  name         = "storage-deny-public-network-access"
  display_name = "Storage accounts should disable public network access"
  mode         = "Indexed"
  policy_type  = "Custom"
  management_group_id = azurerm_management_group.org.id

  policy_rule = jsonencode({
    if = {
      allOf = [
        { field = "type", equals = "Microsoft.Storage/storageAccounts" },
        { field = "Microsoft.Storage/storageAccounts/networkAcls.defaultAction", equals = "Allow" }
      ]
    }
    then = { effect = "deny" }
  })

  metadata = jsonencode({ category = "Storage" })
}

resource "azurerm_management_group_policy_assignment" "storage_deny_public_access" {
  name                 = "storage-deny-public-network-access"
  management_group_id  = azurerm_management_group.org.id
  policy_definition_id = azurerm_policy_definition.storage_deny_public_access.id
}

###############################################################
# 4. Guardrails for Cognitive Services (Azure OpenAI)          #
#    - Deny public network access                              #
#    - Enforce CMK via Key Vault                               #
###############################################################

# Custom policy: Deny Cognitive Services accounts with public network access enabled
resource "azurerm_policy_definition" "cogsvc_deny_public_access" {
  name         = "cogsvc-deny-public-network-access"
  display_name = "Cognitive Services accounts should disable public network access"
  mode         = "Indexed"
  policy_type  = "Custom"
  management_group_id = azurerm_management_group.org.id

  policy_rule = jsonencode({
    if = {
      allOf = [
        { field = "type", equals = "Microsoft.CognitiveServices/accounts" },
        { field = "Microsoft.CognitiveServices/accounts/publicNetworkAccess", equals = "Enabled" }
      ]
    }
    then = { effect = "deny" }
  })

  metadata = jsonencode({ category = "Cognitive Services" })
}

resource "azurerm_management_group_policy_assignment" "cogsvc_deny_public_access" {
  name                 = "cogsvc-deny-public-network-access"
  management_group_id  = azurerm_management_group.org.id
  policy_definition_id = azurerm_policy_definition.cogsvc_deny_public_access.id

  metadata = <<METADATA
    { "category": "Cognitive Services", "assignedBy": "Terraform – org_guardrails module" }
METADATA
}

# Custom policy: Enforce CMK (Key Vault) for Cognitive Services encryption
resource "azurerm_policy_definition" "cogsvc_require_cmk" {
  name         = "cogsvc-require-cmk"
  display_name = "Cognitive Services accounts should use customer-managed keys"
  mode         = "Indexed"
  policy_type  = "Custom"
  management_group_id = azurerm_management_group.org.id

  policy_rule = jsonencode({
    if = {
      allOf = [
        { field = "type", equals = "Microsoft.CognitiveServices/accounts" },
        { not = { field = "Microsoft.CognitiveServices/accounts/encryption.keySource", equals = "Microsoft.KeyVault" } }
      ]
    }
    then = { effect = "deny" }
  })

  metadata = jsonencode({ category = "Cognitive Services" })
}

resource "azurerm_management_group_policy_assignment" "cogsvc_require_cmk" {
  name                 = "cogsvc-require-cmk"
  management_group_id  = azurerm_management_group.org.id
  policy_definition_id = azurerm_policy_definition.cogsvc_require_cmk.id

  metadata = <<METADATA
    { "category": "Cognitive Services", "assignedBy": "Terraform – org_guardrails module" }
METADATA
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
