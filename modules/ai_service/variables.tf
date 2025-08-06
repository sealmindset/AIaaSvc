variable "location" {
  description = "Azure region (e.g. eastus2)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource-group that hosts the AI service"
  type        = string
}

variable "vnet_id" {
  description = "ID of the spoke VNet"
  type        = string
}

variable "subnets" {
  description = "Map of subnet IDs (expects keys: pe, gateway)"
  type        = map(string)
}

variable "key_vault_key_id" {
  description = "Key Vault Key ID used for CMK encryption (e.g. /keys/.../...)"
  type        = string
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
