
# Create these resources in am-dev-rg, but keep the network within sdp-hadoop-rg
resource "azurerm_resource_group" "rg" {
  name     = "${var.project}-${var.environment}-rg"
  location = "westeurope"
}

module "firewall" {
  source = "../firewall"
  project = "${var.project}"
  environment = "${var.environment}"
  location = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  ip_whitelist = "${var.ip_whitelist}"
}

# Create virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.project}-${var.environment}-vnet"
  address_space       = ["10.30.1.0/25","10.30.2.0/25", "10.30.3.0/25"]
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
}

# Create subnets
resource "azurerm_subnet" "defaultsubnet" {
  name                 = "default"
  resource_group_name  = "${azurerm_virtual_network.vnet.resource_group_name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "10.30.1.0/25"
  network_security_group_id = "${module.firewall.id}"
}

resource "azurerm_subnet" "sparksubnet" {
  name                 = "spark"
  resource_group_name  = "${azurerm_virtual_network.vnet.resource_group_name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "10.30.2.0/25"
  network_security_group_id = "${module.firewall.id}"
}

resource "azurerm_subnet" "hivesubnet" {
  name                 = "hive"
  resource_group_name  = "${azurerm_virtual_network.vnet.resource_group_name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "10.30.3.0/25"
  network_security_group_id = "${module.firewall.id}"
}

# count is not supported for modules, see https://github.com/hashicorp/terraform/issues/953

# -- NiFi 1.5 - cluster 3 nodes

module "nifi-1_5-01" {
  source = "../vm"
  environment = "${var.environment}"
  vmname = "vm-${var.environment}-nifi01"
  vmsize = "Standard_F8s"
  role = "nifi15"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  // TODO: use mgnt subnet for now until dev has its own subnet
  //  subnet_id = "${azurerm_subnet.defaultsubnet.id}"
  subnet_id = "/subscriptions/dd10eed9-865c-4bfa-a260-d3e8fe16b047/resourceGroups/sdp-hadoop-rg/providers/Microsoft.Network/virtualNetworks/sdp-hadoop-vnet/subnets/default"
  tags = {
    "cluster" = "nifi3${var.environment}1"
  }
  auto_start_stop = "no"
}
module "nifi-1_5-02" {
  source = "../vm"
  environment = "${var.environment}"
  vmname = "vm-${var.environment}-nifi02"
  vmsize = "Standard_F8s_v2"
  role = "nifi15"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  // TODO: use mgnt subnet for now until dev has its own subnet
  //  subnet_id = "${azurerm_subnet.defaultsubnet.id}"
  subnet_id = "/subscriptions/dd10eed9-865c-4bfa-a260-d3e8fe16b047/resourceGroups/sdp-hadoop-rg/providers/Microsoft.Network/virtualNetworks/sdp-hadoop-vnet/subnets/default"
  tags = {
    "cluster" = "nifi3${var.environment}1"
  }
  auto_start_stop = "no"
}
module "nifi-1_5-03" {
  source = "../vm"
  environment = "${var.environment}"
  vmname = "vm-${var.environment}-nifi03"
  vmsize = "Standard_F8s_v2"
  role = "nifi15"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  // TODO: use mgnt subnet for now until dev has its own subnet
  //  subnet_id = "${azurerm_subnet.defaultsubnet.id}"
  subnet_id = "/subscriptions/dd10eed9-865c-4bfa-a260-d3e8fe16b047/resourceGroups/sdp-hadoop-rg/providers/Microsoft.Network/virtualNetworks/sdp-hadoop-vnet/subnets/default"
  tags = {
    "cluster" = "nifi3${var.environment}1"
  }
  auto_start_stop = "no"
}
module "nifi-1_5-04" {
  source = "../vm"
  environment = "${var.environment}"
  vmname = "vm-${var.environment}-nifi04"
  vmsize = "Standard_F8s_v2"
  role = "nifi15"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  // TODO: use mgnt subnet for now until dev has its own subnet
  //  subnet_id = "${azurerm_subnet.defaultsubnet.id}"
  subnet_id = "/subscriptions/dd10eed9-865c-4bfa-a260-d3e8fe16b047/resourceGroups/sdp-hadoop-rg/providers/Microsoft.Network/virtualNetworks/sdp-hadoop-vnet/subnets/default"
  auto_start_stop = "no"
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