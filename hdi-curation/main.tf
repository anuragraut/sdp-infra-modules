
resource "azurerm_resource_group" "rg" {
    name     = "${var.environment}-curation-rg"
    location = "westeurope"
}

resource "azurerm_storage_account" "sa" {
  name                     = "${var.project}${var.clusterid}${var.environment}curationsa"
  resource_group_name      = "${azurerm_resource_group.rg.name}"
  location                 = "${azurerm_resource_group.rg.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_data_lake_store" "dl" {
  name                  = "${var.share_datalake ?  join("" , list(var.project,var.clusterid,var.environment, "datalakeadls"))  : join("", list(var.project,var.clusterid,var.environment,"curationadls"))}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  location              = "${azurerm_resource_group.rg.location}"
}

resource "azurerm_key_vault" "kv" {
  name                        = "${var.project}-${var.environment}-common-kv"
  location                    = "${azurerm_resource_group.rg.location}"
  resource_group_name         = "${azurerm_resource_group.rg.name}"
  tenant_id                   = "98fbb231-4a93-4dee-85a8-9c286ddfb92d"

  sku {
    name = "standard"
   }
}

resource "azurerm_virtual_network" "vnet01" {
  name = "${var.project}-${var.clusterid}-${var.environment}-curation-vnet"
  address_space = ["10.${var.ipid01}.1.0/25","10.${var.ipid01}.2.0/25","10.${var.ipid01}.3.0/25"]
  location = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  dns_servers = "${compact(list(var.active_directory ? "10.90.80.4" : "", var.active_directory ? "10.90.80.5" : ""))}"

  provisioner "local-exec" {
    command = "sleep 60"
  }
}

resource "azurerm_subnet" "datagatewaysubnet01" {
  name                 = "datagateway"
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
  name                 = "processing"
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
resource "azurerm_sql_server" "sqlserver" {
  name                = "${var.project}${var.clusterid}${var.environment}curationsql"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
  version             = "${var.sqlversion}"
  administrator_login = "${var.project}-admin"
  administrator_login_password = "${var.sql_pwd_secret}d5K9KmY%d"
  count               = "${var.externaldb == "yes" ? 1 : 0}"
}

resource "azurerm_sql_database" "ooziemetastore" {
  name                = "${var.project}${var.clusterid}${var.environment}curationooziemetastore"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
  server_name         = "${azurerm_sql_server.sqlserver.name}"
}

resource "azurerm_sql_database" "hivemetastore01" {
  name                = "${var.project}${var.clusterid}${var.environment}curationhivemetastore"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
  server_name         = "${azurerm_sql_server.sqlserver.name}"
}

resource "azurerm_sql_database" "rangerdb01" {
  name                = "${var.project}${var.clusterid}${var.environment}curationrangerdb"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
  server_name         = "${azurerm_sql_server.sqlserver.name}"
}

module "firewall01" {
  source = "../firewall"
  project = "${var.project}"
  environment = "${var.clusterid}-${var.environment}-curation" #Complete Name: ${var.project}-${var.clusterid}-${var.environment}-nsg
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
