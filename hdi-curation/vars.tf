variable "project" {
  description = "This is a string to define the project, for SIT, UAT and PRD use gl"
}

variable "clusterid" {
  description = "Unique identifier (used in Cluster name), must be in range 01-19"
}

variable "ipid01" {
  description = "Unique identifier (used in IP ranges), must be in range 100-255"
}

variable "ip_whitelist" {
  type = "map"
}

variable "active_directory" {
  default = true
}

variable "externaldb" {
  default = "yes"
}

variable "sql_pwd_secret" {
}

variable "environment" {
  default = "dev"
}

variable "sqlversion" {
  default = "12.0"
}

variable "share_datalake" {
  default = false
}
