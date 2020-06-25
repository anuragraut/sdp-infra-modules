
resource "azurerm_resource_group" "rg" {
  name     = "${var.project}-${var.environment}-rg"
  location = "westeurope"
}

module "firewall" {
  source              = "../firewall"
  project             = "${var.project}"
  #environment         = "${var.environment}"
  environment         = "nifi"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  ip_whitelist        = "${var.ip_whitelist}"
}

# Create virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.project}-${var.environment}-vnet"
  address_space       = ["10.11.0.0/16","10.12.0.0/16", "10.13.0.0/16"]
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
}

# Create subnets
resource "azurerm_subnet" "defaultsubnet" {
  name                 = "default"
  resource_group_name  = "${azurerm_virtual_network.vnet.resource_group_name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "10.11.0.0/24"
  network_security_group_id = "${module.firewall.id}"
}

resource "azurerm_subnet" "sparksubnet" {
  name                 = "spark"
  resource_group_name  = "${azurerm_virtual_network.vnet.resource_group_name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "10.12.0.0/24"
  network_security_group_id = "${module.firewall.id}"
}

resource "azurerm_subnet" "hivesubnet" {
  name                 = "hive"
  resource_group_name  = "${azurerm_virtual_network.vnet.resource_group_name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "10.13.0.0/24"
  network_security_group_id = "${module.firewall.id}"
}

module "jira01" {
  source = "../vm"
  #environment = "${var.environment}"
  environment = "common"
  vmname = "vm-dev-jira01"
  vmsize = "Standard_B2s"
  role = "jira"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  subnet_id = "${azurerm_subnet.defaultsubnet.id}"
  auto_start_stop     = "${var.auto_start_stop}"
}

module "bitbucket01" {
  source = "../vm"
  #environment = "${var.environment}"
  environment = "common"
  vmname = "vm-dev-bitbucket01"
  vmsize = "Standard_B2s"
  role = "bitbucket"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  subnet_id = "${azurerm_subnet.defaultsubnet.id}"
  auto_start_stop     = "${var.auto_start_stop}"
}

module "jenkins01" {
  source = "../vm"
  #environment = "${var.environment}"
  environment = "common"
  vmname = "vm-dev-jenkins01"
  vmsize = "Standard_B4ms"
  role = "jenkins"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  subnet_id = "${azurerm_subnet.defaultsubnet.id}"
  additional_subnet_ids = ["${azurerm_subnet.sparksubnet.id}"]
  managed_disk_type = "Standard_LRS"
  auto_start_stop     = "${var.auto_start_stop}"
}

module "nexus01" {
  source = "../vm"
  #environment = "${var.environment}"
  environment = "common"
  vmname = "vm-dev-nexus01"
  vmsize = "Standard_F2s"
  os_sku = "7.2"
  role = "nexus"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  subnet_id = "${azurerm_subnet.defaultsubnet.id}"
  managed_disk_type = "Standard_LRS"
  auto_start_stop     = "${var.auto_start_stop}"
}

# The human accesible jumpbox - Devoteam
module "jumpbox" {
  source = "../publicvm"
  #environment = "${var.environment}"
  environment = "common"
  vmname = "vm-dev-jumpbox"
  vmsize = "Standard_B2s"
  role = "jumpbox-devoteam"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  subnet_id = "${azurerm_subnet.defaultsubnet.id}"
  additional_subnet_ids = ["${azurerm_subnet.hivesubnet.id}", "${azurerm_subnet.sparksubnet.id}"]
  additional_disk_size = "1"
  auto_start_stop     = "${var.auto_start_stop}"
}

module "gateway"{
  source = "../vm_win"
  environment = "common"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location = "westeurope"
  vmname = "vm-dev-gateway"
  vmsize = "Standard_F2"
  os_sku = "2016-Datacenter"
  managed_disk_type = "Standard_LRS"
  additional_disk_size = "1"
  role = "gateway-devoteam"
  auto_start_stop = "yes"
  subnet_id = "${azurerm_subnet.defaultsubnet.id}"
  additional_subnet_ids = []
}