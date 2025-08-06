variable "location" {
  description = "Azure region, e.g. eastus2"
  type        = string
}

variable "hub_address_space" {
  description = "CIDR(s) for the hub VNet"
  type        = list(string)
}

variable "spoke_address_space" {
  description = "CIDR(s) for the AI spoke VNet"
  type        = list(string)
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
