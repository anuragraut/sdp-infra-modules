
variable "project" {
}

variable "ip_whitelist" {
  type = "map"
}

variable "tenant_id" {
  default = "98fbb231-4a93-4dee-85a8-9c286ddfb92d"
}

variable "owners" {
  type = "list"
  description = "Users, groups or service principals that are owners of the project. Can see secrets"
  default = []
}

variable "admins" {
  type = "list"
  description = "Users, groups or service principals that are adminds of the project. Can not see secrets, but can set them"
  # Environment management:
  default = ["49cb0410-986f-4d77-af2d-d4b48d35f0fd"]
}