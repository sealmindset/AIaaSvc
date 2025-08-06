variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource-group that hosts Log Analytics & Storage"
  type        = string
}

variable "resources_to_monitor" {
  description = "List of Azure resource IDs the module must attach Diagnostic Settings to"
  type        = list(string)
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
