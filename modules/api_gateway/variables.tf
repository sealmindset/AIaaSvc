variable "location"       { type = string }
variable "rg_name"        { type = string }
variable "vnet_id"        { type = string }
variable "subnet_id"      { type = string }
variable "kv_id"          { type = string }
variable "openai_account_id" { type = string }
variable "openai_endpoint"   { type = string }
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
