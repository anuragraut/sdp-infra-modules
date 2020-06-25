
variable "project" {
}

variable "ip_whitelist" {
  type = "map"
}

variable "environment" {
  description = "Environment, for example dev, uat, prod ..."
  default = "pilot"
}

