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

# Optional CMK controls for Cognitive Services (lab-safe defaults)
variable "enable_cmk" {
  description = "Enable CMK encryption for Cognitive Services (requires key_vault_key_id)"
  type        = bool
  default     = false
}

variable "key_vault_key_id" {
  description = "Key Vault Key ID for CMK (format: /subscriptions/.../resourceGroups/.../providers/Microsoft.KeyVault/vaults/<name>/keys/<key>/<version>)"
  type        = string
  default     = ""
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

# Hybrid auth variables for API Gateway module
variable "aad_tenant_id" {
  description = "Azure AD tenant ID used by APIM validate-jwt"
  type        = string
}

variable "aad_audience" {
  description = "Audience (api://<app-id-uri> or application ID) expected in JWTs"
  type        = string
}

variable "ui_token_validate_url" {
  description = "URL of uiapikms token validation endpoint (POST { token })"
  type        = string
}
