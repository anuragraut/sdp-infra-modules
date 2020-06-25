
resource "azurerm_resource_group" "rg" {
    name     = "${var.resouce_group_name}"
    location = "westeurope"
}

resource "azurerm_data_lake_store" "dl" {
  name                  = "${var.data_lake_name}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  location              = "${azurerm_resource_group.rg.location}"
}


resource "azurerm_virtual_network" "vnet01" {
  name = "${var.project}-${var.subcluster01}${var.clusterid}-vnet"
  address_space = ["10.${var.ipid01}.1.0/25","10.${var.ipid01}.2.0/25","10.${var.ipid01}.3.0/25"]
  location = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  dns_servers = "${compact(list(var.active_directory ? "10.90.80.4" : "", var.active_directory ? "10.90.80.5" : ""))}"

  provisioner "local-exec" {
    command = "sleep 60"
  }
}

resource "azurerm_subnet" "datagatewaysubnet01" {
  name                 = "${var.project}-${var.subcluster01}${var.clusterid}-datagateway"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet01.name}"
  address_prefix       = "10.${var.ipid01}.1.0/25"
  network_security_group_id = "${module.firewall01.id}"

  provisioner "local-exec" {
    command = "echo 'sleeping for 60 seconds'"
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }
}

resource "azurerm_subnet" "processingsubnet01" {
  name                 = "${var.project}-${var.subcluster01}${var.clusterid}-processing"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet01.name}"
  address_prefix       = "10.${var.ipid01}.2.0/25"
  network_security_group_id = "${module.firewall01.id}"

  provisioner "local-exec" {
    command = "echo 'sleeping for 60 seconds'"
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }
}

# Database server creation
resource "azurerm_sql_server" "sqlserver01" {
  name                = "${var.project}${var.subcluster01}${var.clusterid}sql"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
  version             = "${var.sqlversion}"
  administrator_login = "${var.project}${var.subcluster01}-admin"
  administrator_login_password = "%dP_5dKlN"
  count               = "${var.externaldb == "yes" ? 1 : 0}"
}

resource "azurerm_sql_database" "ooziemetastore01" {
  name                = "${var.project}${var.subcluster01}${var.clusterid}ooziemetastore"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
  server_name         = "${azurerm_sql_server.sqlserver01.name}"
}

resource "azurerm_sql_database" "hivemetastore01" {
  name                = "${var.project}${var.subcluster01}${var.clusterid}hivemetastore"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
  server_name         = "${azurerm_sql_server.sqlserver01.name}"
}

resource "azurerm_sql_database" "rangerdb01" {
  name                = "${var.project}${var.subcluster01}${var.clusterid}rangerdb"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
  server_name         = "${azurerm_sql_server.sqlserver01.name}"
}

module "firewall01" {
  source = "../firewall"
  project = "${var.project}"
  environment = "${var.subcluster01}${var.clusterid}"
  location = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  ip_whitelist = "${var.ip_whitelist}"
}

output "resource_group_name" {
  value = "${azurerm_resource_group.rg.name}"
}

output "vnet01_name" {
  value = "${azurerm_virtual_network.vnet01.name}"
}

output "vnet01_id" {
  value = "${azurerm_virtual_network.vnet01.id}"
}
