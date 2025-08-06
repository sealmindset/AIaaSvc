output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.law.id
}

output "storage_account_id" {
  value = azurerm_storage_account.diag.id
}
