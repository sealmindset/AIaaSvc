variable "location" {
  type        = string
  description = "Azure region for sandbox resources"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to sandbox resources"
  default     = {}
}

variable "oauth_client_id" {
  type        = string
  description = "OAuth2 client ID"
}

variable "oauth_client_secret" {
  type        = string
  description = "OAuth2 client secret"
  sensitive   = true
}

variable "oauth_authorization_url" {
  type        = string
  description = "OAuth2 authorization URL"
}

variable "oauth_token_url" {
  type        = string
  description = "OAuth2 token URL"
}
