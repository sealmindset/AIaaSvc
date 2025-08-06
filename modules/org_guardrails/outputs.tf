output "management_group_id" {
  value = azurerm_management_group.org.id
}

output "policy_assignment_ids" {
  value = [
    azurerm_management_group_policy_assignment.allowed_locations.id,
    azurerm_management_group_policy_assignment.require_tags.id
  ]
}
