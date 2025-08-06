variable "mg_name" {
  description = "Name of the management group to deploy resources in, e.g. 'mg-ai'"
  type        = string
}

variable "allowed_locations" {
  description = "List of Azure regions allowed for resource deployment"
  type        = list(string)
  default     = []
}

variable "location" {
  description = "Primary Azure region for shared resources"
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}
