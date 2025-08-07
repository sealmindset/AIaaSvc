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

# Sandbox APIM toggle and OAuth variables
variable "create_sandbox" {
  description = "Whether to deploy sandbox APIM resources"
  type        = bool
  default     = false
}

variable "oauth_client_id" {
  description = "OAuth2 client ID for sandbox APIM"
  type        = string
  default     = ""
}

variable "oauth_client_secret" {
  description = "OAuth2 client secret for sandbox APIM"
  type        = string
  sensitive   = true
  default     = ""
}

variable "oauth_authorization_url" {
  description = "OAuth2 authorization URL for sandbox APIM"
  type        = string
  default     = ""
}

variable "oauth_token_url" {
  description = "OAuth2 token URL for sandbox APIM"
  type        = string
  default     = ""
}
