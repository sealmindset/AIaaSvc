output "hub_rg_id" {
  description = "Resource-group ID for the hub VNet (shared services)"
  value       = azurerm_resource_group.hub.id
}

output "hub_rg_name" {
  description = "Name of the hub resource-group"
  value       = azurerm_resource_group.hub.name
}

output "spoke_rg_id" {
  description = "Resource-group ID for the AI spoke"
  value       = azurerm_resource_group.spoke.id
}

output "spoke_rg_name" {
  value = azurerm_resource_group.spoke.name
}

output "spoke_vnet_id" {
  description = "VNet ID for the AI spoke"
  value       = azurerm_virtual_network.spoke.id
}

output "spoke_subnets" {
  description = "Map of subnet IDs in the spoke"
  value = {
    pe      = azurerm_subnet.pe.id
    gateway = azurerm_subnet.gateway.id
  }
}

output "kv_id" {
  description = "Key Vault ID (for CMKs)"
  value       = azurerm_key_vault.kv.id
}


