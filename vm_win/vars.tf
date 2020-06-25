
variable "projekt" {
  description = "Name of the project, e.g. PEDP"
  default = "PEDP"
}

variable "resource_group_name" {
  description = "Azure Resouce Group"
}

variable "location" {
  description = "Location"
  default = "westeurope"
}

variable "environment" {
  description = "Environment, for example dev, uat, prod ..."
}

variable "vmname" {
  description = "vm-dev-gateway"
}

variable "vmsize" {
  default = "Standard_F2"
  description = "Virtual machine size, see https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes"
}

variable "os_sku" {
  default = "2016-Datacenter"
}

variable "managed_disk_type" {
  description = "Disk type to use"
  default = "Standard_LRS"
}

variable "additional_disk_size" {
  description = "Any additional disk size in GB"
  default = 32
}

variable "role" {
  description = "role of this machine (also used by Ansible)"
}

variable "tags" {
  type = "map"
  description = "Tags to add to the Virtual Machine"
  default = {}
}

variable "auto_start_stop" {
  description = "Whether this node should automatically be started/stopped by Azure"
  default = "yes"
}

variable "subnet_id" {
  description = "Place the VM into this subnet of the Virtual Network"
}

variable "network_security_group_id" {
  description = "Network Security Group"
  default = "/subscriptions/dd10eed9-865c-4bfa-a260-d3e8fe16b047/resourceGroups/sdp-hadoop-rg/providers/Microsoft.Network/networkSecurityGroups/sdp-nifi-nsg"
  #default = "sdp-nifi-nsg"
}

variable "additional_subnet_ids" {
  type = "list"
  description = "additional subnet server will be in"
  default = []
}