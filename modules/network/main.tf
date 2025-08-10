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

data "azurerm_client_config" "current" {}

############################
# 1. Hub (shared services) #
############################
resource "azurerm_resource_group" "hub" {
  name     = "rg-network-hub"
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub"
  address_space       = var.hub_address_space
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  tags                = var.tags
}

# Dedicated subnet for Azure Firewall
// Azure Firewall removed per design – using external firewall service
// resource "azurerm_subnet" "firewall_subnet" {
//   name                 = "AzureFirewallSubnet"
//   resource_group_name  = azurerm_resource_group.hub.name
//   virtual_network_name = azurerm_virtual_network.hub.name
//   address_prefixes     = ["10.0.1.0/26"]
// }

# Public IP (Mgmt only — egress still blocked by rules)
// Azure Firewall public IP removed
// resource "azurerm_public_ip" "firewall_pip" {
//   name                = "pip-fw-hub"
//   location            = var.location
//   resource_group_name = azurerm_resource_group.hub.name
//   allocation_method   = "Static"
//   sku                 = "Standard"
//   tags                = var.tags
// }

// Azure Firewall resource removed
// resource "azurerm_firewall" "fw" { ... }

##################################
# 2. Spoke (AI-as-a-Service VNet) #
##################################
resource "azurerm_resource_group" "spoke" {
  name     = "rg-ai-spoke"
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-ai-spoke"
  address_space       = var.spoke_address_space
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke.name
  tags                = var.tags
}

# Subnet for private endpoints (OpenAI, Key Vault, etc.)
resource "azurerm_subnet" "pe" {
  name                 = "snet-pe"
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = ["10.1.0.0/25"]
  service_endpoints   = [
    "Microsoft.Storage",
    "Microsoft.KeyVault"
  ]
}

# Subnet for APIM / gateway tier
resource "azurerm_subnet" "gateway" {
  name                 = "snet-gateway"
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = ["10.1.0.128/25"]
  service_endpoints   = [
    "Microsoft.Storage",
    "Microsoft.KeyVault"
  ]
}

# Network Security Group for gateway subnet (minimal defaults)
resource "azurerm_network_security_group" "gateway" {
  name                = "nsg-ai-gateway"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke.name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "gateway" {
  subnet_id                 = azurerm_subnet.gateway.id
  network_security_group_id = azurerm_network_security_group.gateway.id
}

# Allow APIM control-plane inbound (management) on TCP 3443 from Azure ApiManagement service tag
resource "azurerm_network_security_rule" "apim_mgmt_inbound" {
  name                        = "apim-mgmt-allow-3443"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3443"
  source_address_prefix       = "ApiManagement"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.spoke.name
  network_security_group_name = azurerm_network_security_group.gateway.name
}

###################################
# 3. Routing — force all egress   #
#    through the Azure Firewall   #
###################################
// Route table to Azure Firewall removed – egress will follow system/default routes or external firewall solution
// resource "azurerm_route_table" "spoke_to_fw" { ... }

// Route table associations removed
// resource "azurerm_subnet_route_table_association" "pe_rta" { ... }
// resource "azurerm_subnet_route_table_association" "gateway_rta" { ... }

##########################
# 4. Hub–Spoke Peering   #
##########################
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "hub-to-spoke"
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "spoke-to-hub"
  resource_group_name       = azurerm_resource_group.spoke.name
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
  allow_forwarded_traffic   = true
}

########################
# 5. Key Vault (CMKs)  #
########################
resource "azurerm_key_vault" "kv" {
  name                     = "kv-ai-${substr(uuid(), 0, 6)}"
  location                 = var.location
  resource_group_name      = azurerm_resource_group.hub.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  sku_name                 = "standard"
  purge_protection_enabled = true

  network_acls {
    default_action             = "Deny"
    bypass                     = "None"
    virtual_network_subnet_ids = [azurerm_subnet.gateway.id, azurerm_subnet.pe.id]
    ip_rules                   = []
  }

  tags = var.tags
}
