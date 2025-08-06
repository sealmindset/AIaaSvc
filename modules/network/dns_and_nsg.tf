##############################
# Private DNS Zones + Links #
##############################

locals {
  # Add any required private DNS zones here
  private_dns_zone_names = [
    "privatelink.openai.azure.com",
    "privatelink.azure-api.net",
    "privatelink.blob.core.windows.net",
  ]
}

resource "azurerm_private_dns_zone" "zones" {
  for_each            = toset(local.private_dns_zone_names)
  name                = each.value
  resource_group_name = azurerm_resource_group.hub.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "zones_link" {
  for_each = azurerm_private_dns_zone.zones

  name                  = "${each.key}-spoke-link"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = each.value.name
  virtual_network_id    = azurerm_virtual_network.spoke.id
  registration_enabled  = false
}

##############################
# Network Security Groups    #
##############################

resource "azurerm_network_security_group" "spoke" {
  name                = "nsg-ai-spoke"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke.name
  tags                = var.tags
}

# Example outbound HTTPS rule (modify as needed)
resource "azurerm_network_security_rule" "spoke_allow_https_out" {
  name                        = "Allow-HTTPS-Out"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "Internet"
  network_security_group_name = azurerm_network_security_group.spoke.name
  resource_group_name         = azurerm_resource_group.spoke.name
}

# Associate NSG with Private Endpoint subnet and Gateway subnet
resource "azurerm_subnet_network_security_group_association" "pe_assoc" {
  subnet_id                 = azurerm_subnet.pe.id
  network_security_group_id = azurerm_network_security_group.spoke.id
}

resource "azurerm_subnet_network_security_group_association" "gateway_assoc" {
  subnet_id                 = azurerm_subnet.gateway.id
  network_security_group_id = azurerm_network_security_group.spoke.id
}
