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
