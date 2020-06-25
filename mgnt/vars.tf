
variable "project" {
}

variable "environment" {
}

variable "auto_start_stop" {
  default = "no"
}

variable "ip_whitelist" {
  type = "map"
}