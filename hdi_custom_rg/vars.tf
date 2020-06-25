variable "project" {
}

variable "resouce_group_name" {
}

variable "ipid01" {
  description = "Unique identifier (used in IP ranges), must be in range 100-255"
}

variable "auto_start_stop" {
  default = "yes"
}

variable "ip_whitelist" {
  type = "map"
}

variable "active_directory" {
  default = false
}

variable "externaldb" {
  default = "yes"
}

variable "subcluster01" {
}

variable "environment" {
}

variable "data_lake_name" {
}

variable "sqlversion" {
}

variable "clusterid" {
}

