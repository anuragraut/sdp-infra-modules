
variable "project" {
  default = "sdp"
}

variable "environment" {
}

variable "resource_group_name" {
}

variable "location" {
}

variable "ip_whitelist" {
  type = "map"
  description = "IPs to be whitelisted"
}
