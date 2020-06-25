
resource "azurerm_resource_group" "rg" {
    name     = "${var.project}-${var.name}${var.type}-rg"
    location = "westeurope"
}

resource "azurerm_storage_account" "sa" {
  name                     = "${var.project}${var.name}"
  resource_group_name      = "${azurerm_resource_group.rg.name}"
  location                 = "${azurerm_resource_group.rg.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_data_lake_store" "dl" {
  name                  = "${var.project}${var.name}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  location                 = "${azurerm_resource_group.rg.location}"
}

resource "azurerm_virtual_network" "vnet" {
  name = "${var.project}-${var.name}-vnet"
  address_space = ["10.${var.id}.1.0/25","10.${var.id}.2.0/25","10.${var.id}.3.0/25"]
  location = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  dns_servers = "${compact(list(var.active_directory ? "10.90.80.4" : "", var.active_directory ? "10.90.80.5" : ""))}"

  provisioner "local-exec" {
    command = "sleep 60"
  }
}

resource "azurerm_subnet" "datagatewaysubnet" {
  name                 = "datagateway"
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

# Database server creation
resource "azurerm_sql_server" "sqlserver" {
  name                = "${var.project}${var.name}sql"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
  version             = "12.0"
  administrator_login = "${var.project}_admin"
  administrator_login_password = "$dP_4dm1N"
  count               = "${var.externaldb == "yes" ? 1 : 0}"
}

resource "azurerm_sql_database" "ooziemetastore" {
  name                = "${var.project}${var.name}ooziemetastore"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
  server_name         = "${azurerm_sql_server.sqlserver.name}"
}

resource "azurerm_sql_database" "hivemetastore" {
  name                = "${var.project}${var.name}hivemetastore"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
  server_name         = "${azurerm_sql_server.sqlserver.name}"
}

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
  vmsize              = "Standard_F2s"
  role                = "nifi18"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  subnet_id           = "${azurerm_subnet.datagatewaysubnet.id}"
  auto_start_stop     = "${var.auto_start_stop}"

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
