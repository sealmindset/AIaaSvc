variable "location" { type = string }
variable "rg_name" { type = string }
variable "vnet_id" { type = string }
variable "subnet_id" { type = string }
variable "kv_id" { type = string }
variable "openai_account_id" { type = string }
variable "openai_endpoint" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}

# Optional list of AAD object IDs that receive pre-provisioned subscriptions
variable "initial_user_object_ids" {
  description = "Optional list of AAD object IDs that receive pre-provisioned subscriptions"
  type        = list(string)
  default     = []
}

# Hybrid auth config for APIM policies
# Entra ID tenant to validate JWTs against (format: GUID tenant ID)
variable "aad_tenant_id" {
  description = "Azure AD tenant ID used by APIM validate-jwt"
  type        = string
  default     = "00000000-0000-0000-0000-000000000000"
}

# Audience (Application ID URI or App ID) expected in client JWTs
variable "aad_audience" {
  description = "Audience (api://<app-id-uri> or application ID) expected in JWTs"
  type        = string
  default     = "api://replace-with-your-app-id-uri"
}

# UI token validation endpoint for opaque tokens (POST { token: string })
variable "ui_token_validate_url" {
  description = "URL of uiapikms token validation endpoint"
  type        = string
  default     = "https://your-ui-domain.example.com/api/tokens/validate"
}
