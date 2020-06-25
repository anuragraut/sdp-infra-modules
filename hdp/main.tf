
resource "azurerm_resource_group" "rg" {
    name     = "sdp-${var.name}-rg"
    location = "westeurope"
}

resource "azurerm_storage_account" "sa" {
  name                     = "sdp${var.name}"
  resource_group_name      = "${azurerm_resource_group.rg.name}"
  location                 = "${azurerm_resource_group.rg.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_data_lake_store" "dl" {
  name                  = "sdp${var.name}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  location                 = "${azurerm_resource_group.rg.location}"
}

resource "azurerm_virtual_network" "vnet" {
  name = "sdp-${var.name}-vnet"
  address_space = ["10.${var.id}.1.0/25","10.${var.id}.2.0/25","10.${var.id}.3.0/25"]
  location = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  dns_servers = "${compact(list(var.active_directory ? "10.90.80.4" : "", var.active_directory ? "10.90.80.5" : ""))}"

  provisioner "local-exec" {
    command = "sleep 60"
  }
}

resource "azurerm_subnet" "ingestionsubnet" {
  name                 = "ingestion"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "10.${var.id}.1.0/25"
  network_security_group_id = "${module.firewall.id}"

  provisioner "local-exec" {
    command = "echo 'sleeping for 60 seconds'"
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }
}

resource "azurerm_subnet" "processingsubnet" {
  name                 = "processing"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "10.${var.id}.2.0/25"
  network_security_group_id = "${module.firewall.id}"

  provisioner "local-exec" {
    command = "echo 'sleeping for 60 seconds'"
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }
}

#resource "azurerm_subnet" "consumptionsubnet" {
#  name                 = "consumption"
#  resource_group_name  = "${azurerm_resource_group.rg.name}"
#  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
#  address_prefix       = "10.${var.id}.3.0/25"
#  network_security_group_id = "${module.firewall.id}"
#
#  provisioner "local-exec" {
#      command = "echo 'sleeping for 2 seconds'"
#  }
#
#  provisioner "local-exec" {
#      command = "sleep 2"
#  }
#
#}


module "firewall" {
  source = "../firewall"
  environment = "${var.name}"
  location = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  ip_whitelist = "${var.ip_whitelist}"
}

module "nifi01" {
  source              = "../vm"
  environment         = "${var.name}"
  vmname              = "vm-${var.name}-nifi01"
  vmsize              = "Standard_F8s"
  role                = "nifi18"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  subnet_id           = "${azurerm_subnet.ingestionsubnet.id}"
  additional_subnet_ids = ["${azurerm_subnet.processingsubnet.id}"]
  additional_disk_size = "100"
  auto_start_stop     = "${var.auto_start_stop}"
  tags = {
    "cluster" = "nifi3${var.name}"
  }
}

module "nifi02" {
  source              = "../vm"
  environment         = "${var.name}"
  vmname              = "vm-${var.name}-nifi02"
  vmsize              = "Standard_F8s"
  role                = "nifi18"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  subnet_id           = "${azurerm_subnet.ingestionsubnet.id}"
  additional_subnet_ids = ["${azurerm_subnet.processingsubnet.id}"]
  additional_disk_size = "100"
  auto_start_stop     = "${var.auto_start_stop}"
  tags = {
    "cluster" = "nifi3${var.name}"
  }
}

module "nifi03" {
  source              = "../vm"
  environment         = "${var.name}"
  vmname              = "vm-${var.name}-nifi03"
  vmsize              = "Standard_F8s"
  role                = "nifi18"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  subnet_id              = "${azurerm_subnet.ingestionsubnet.id}"
  additional_subnet_ids = ["${azurerm_subnet.processingsubnet.id}"]
  additional_disk_size = "100"
  auto_start_stop     = "${var.auto_start_stop}"
  tags = {
    "cluster" = "nifi3${var.name}"
  }
}

module "nifi01S" {
  source              = "../vm"
  environment         = "${var.name}"
  vmname              = "vm-${var.name}-nifi01s"
  vmsize              = "Standard_F8s"
  role                = "nifi18"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  subnet_id              = "${azurerm_subnet.ingestionsubnet.id}"
  additional_subnet_ids = ["${azurerm_subnet.processingsubnet.id}"]
#  additional_disk_size = "100"
  auto_start_stop     = "${var.auto_start_stop}"
}

module "nifi02S" {
  source              = "../vm"
  environment         = "${var.name}"
  vmname              = "vm-${var.name}-nifi02s"
  vmsize              = "Standard_F8s"
  role                = "nifi18"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  subnet_id              = "${azurerm_subnet.ingestionsubnet.id}"
  additional_subnet_ids = ["${azurerm_subnet.processingsubnet.id}"]
#  additional_disk_size = "100"
  auto_start_stop     = "${var.auto_start_stop}"
}

module "dbserver01" {
  source              = "../vm"
  environment         = "${var.name}"
  vmname              = "vm-${var.name}-dbserver01"
  vmsize              = "Standard_F2"
  managed_disk_type   = "Standard_LRS"
  role                = "mariadb"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  subnet_id              = "${azurerm_subnet.ingestionsubnet.id}"
  additional_subnet_ids = ["${azurerm_subnet.processingsubnet.id}"]
#  additional_disk_size = "100"
  auto_start_stop     = "${var.auto_start_stop}"
}

module "mgnt" {
  source              = "../vm"
  environment         = "${var.name}"
  vmname              = "vm-${var.name}-mgnt01"
  vmsize              = "Standard_D12_v2" # Needs to be this because it needs 3 NICs
  managed_disk_type   = "Standard_LRS"
  role                = "mgnt"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  
  subnet_id              = "${azurerm_subnet.processingsubnet.id}"
  #additional_subnet_ids = ["ingestion","consumption"]
  auto_start_stop     = "${var.auto_start_stop}"
  tags = {
    "hdp-ambari-node" = true
    "hdp-ranger-nodes" = true
    "hdp-node" = true
  }
}

module "master01" {
  source              = "../vm"
  environment         = "${var.name}"
  vmname              = "vm-${var.name}-master01"
  vmsize              = "Standard_D12_v2"
  managed_disk_type   = "Standard_LRS"
  role                = "master1"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  
  subnet_id           = "${azurerm_subnet.processingsubnet.id}"
  #additional_subnet_ids = ["consumption"]
  auto_start_stop     = "${var.auto_start_stop}"
  tags = {
    "hdp-master-node" = true
    "hdp-node" = true
  }
}

module "master02" {
  source              = "../vm"
  environment         = "${var.name}"
  vmname              = "vm-${var.name}-master02"
  vmsize              = "Standard_D12_v2"
  managed_disk_type   = "Standard_LRS"
  role                = "master2"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  subnet_id           = "${azurerm_subnet.processingsubnet.id}"
  #additional_subnet_ids = ["consumption"]
  auto_start_stop     = "${var.auto_start_stop}"
  tags = {
    "hdp-master-node" = true
    "hdp-node" = true
  }
}

module "master03" {
  source              = "../vm"
  environment         = "${var.name}"
  vmname              = "vm-${var.name}-master03"
  vmsize              = "Standard_D12_v2"
  managed_disk_type   = "Standard_LRS"
  role                = "master3"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  subnet_id           = "${azurerm_subnet.processingsubnet.id}"
  #additional_subnet_ids = ["consumption"]
  auto_start_stop     = "${var.auto_start_stop}"
  tags = {
    "hdp-master-node" = true
    "hdp-node" = true
  }
}

module "data01" {
  source              = "../vm_additional_disk"
  environment         = "${var.name}"
  vmname              = "vm-${var.name}-data01"
  vmsize              = "Standard_D16s_v3"
  managed_disk_type   = "Standard_LRS"
  role                = "datanode"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  subnet_id           = "${azurerm_subnet.processingsubnet.id}"
  additional_disk_size = "4000"
  additional_disk01_size = "1000"
  auto_start_stop     = "${var.auto_start_stop}"
  tags = {
    "hdp-slave-node" = true
    "hdp-node" = true
  }
}

module "data02" {
  source              = "../vm_additional_disk"
  environment         = "${var.name}"
  vmname              = "vm-${var.name}-data02"
  vmsize              = "Standard_D16s_v3"
  managed_disk_type   = "Standard_LRS"
  role                = "datanode"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  subnet_id           = "${azurerm_subnet.processingsubnet.id}"
  additional_disk_size = "4000"
  additional_disk01_size = "1000"
  auto_start_stop     = "${var.auto_start_stop}"
  tags = {
    "hdp-slave-node" = true
    "hdp-node" = true
  }
}

module "data03" {
  source              = "../vm_additional_disk"
  environment         = "${var.name}"
  vmname              = "vm-${var.name}-data03"
  vmsize              = "Standard_D16s_v3"
  managed_disk_type   = "Standard_LRS"
  role                = "datanode"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  subnet_id           = "${azurerm_subnet.processingsubnet.id}"
  #additional_subnet_ids = ["consumption"]
  additional_disk_size = "4000"
  additional_disk01_size = "1000"
  auto_start_stop     = "${var.auto_start_stop}"
  tags = {
    "hdp-slave-node" = true
    "hdp-node" = true
  }
}

module "data04" {
  source              = "../vm_additional_disk"
  environment         = "${var.name}"
  vmname              = "vm-${var.name}-data04"
  vmsize              = "Standard_D16s_v3"
  managed_disk_type   = "Standard_LRS"
  role                = "datanode"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  subnet_id           = "${azurerm_subnet.processingsubnet.id}"
  #additional_subnet_ids = ["consumption"]
  additional_disk_size = "4000"
  additional_disk01_size = "1000"
  auto_start_stop     = "${var.auto_start_stop}"
  tags = {
    "hdp-slave-node" = true
    "hdp-node" = true
  }
}

module "data05" {
  source              = "../vm_additional_disk"
  environment         = "${var.name}"
  vmname              = "vm-${var.name}-data05"
  vmsize              = "Standard_D16s_v3"
  managed_disk_type   = "Standard_LRS"
  role                = "datanode"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  subnet_id           = "${azurerm_subnet.processingsubnet.id}"
  #additional_subnet_ids = ["consumption"]
  additional_disk_size = "4000"
  additional_disk01_size = "1000"
  auto_start_stop     = "${var.auto_start_stop}"
  tags = {
    "hdp-slave-node" = true
    "hdp-node" = true
  }
}

module "edge01" {
  source              = "../vm"
  environment         = "${var.name}"
  vmname              = "vm-${var.name}-edge01"
  vmsize              = "Standard_DS12_v2"
  role                = "edge"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  subnet_id           = "${azurerm_subnet.processingsubnet.id}"
  auto_start_stop     = "${var.auto_start_stop}"
  tags = {
    "hdp-slave-node" = true
    "hdp-node" = true
  }
}

module "access01" {
  source              = "../vm"
  environment         = "${var.name}"
  vmname              = "vm-${var.name}-access01"
  vmsize              = "Standard_F2s"
  role                = "access"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  subnet_id           = "${azurerm_subnet.processingsubnet.id}"
  auto_start_stop     = "${var.auto_start_stop}"
  tags = {
    "hdp-slave-node" = true
    "hdp-node" = true
  }
}

output "resource_group_name" {
  value = "${azurerm_resource_group.rg.name}"
}

output "vnet_name" {
  value = "${azurerm_virtual_network.vnet.name}"
}

output "vnet_id" {
  value = "${azurerm_virtual_network.vnet.id}"
}
