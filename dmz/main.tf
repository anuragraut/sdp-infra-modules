
resource "azurerm_resource_group" "rg" {
  name     = "${var.project}-${var.client}-rg"
  location = "westeurope"
}

module "firewall" {
  source              = "../firewall"
  project             = "${var.project}"
  environment         = "${var.client}"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  ip_whitelist        = "${var.ip_whitelist}"
}

# Create virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.project}-${var.client}-vnet"
  address_space       = ["10.5.0.0/29"] # Maxed to 3 IP addresses
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
}

# Create subnets
resource "azurerm_subnet" "defaultsubnet" {
  name                 = "default"
  resource_group_name  = "${azurerm_virtual_network.vnet.resource_group_name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "10.5.0.0/29"
  network_security_group_id = "${module.firewall.id}"
}

# The human accesible jumpbox
module "jumpbox" {
  source = "../publicvm"
  environment = "${var.client}"
  vmname = "vm-dev-jumpbox-${var.client}"
  vmsize = "Standard_B2s"
  role = "jumpbox-${var.client}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  subnet_id = "${azurerm_subnet.defaultsubnet.id}"
  additional_disk_size = "1"
  auto_start_stop     = "${var.auto_start_stop}"
  os_sku = "7.4"
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