variable "mg_name" {
  description = "Name of (or ID for) the tenant-root child Management Group that will hold all landing zones"
  type        = string
}

variable "allowed_locations" {
  description = "List of Azure regions workloads are allowed to deploy to"
  type        = list(string)
}

variable "tags" {
  description = "Common tags applied to resources created by this module"
  type        = map(string)
  default     = {}
}
