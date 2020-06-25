
resource "azurerm_resource_group" "rg" {
  name     = "${var.project}-common"
  location = "westeurope"
}

resource "azurerm_storage_account" "sa" {
  # Name must be unique in the entire world! Not just within our scope
  name                     = "sdp${var.project=="sdp"?"":var.project}common"
  resource_group_name      = "${azurerm_resource_group.rg.name}"
  location                 = "${azurerm_resource_group.rg.location}"
  account_tier             = "Standard"
  account_kind             = "StorageV2"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "sc" {
  name                  = "infra-state"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  storage_account_name  = "${azurerm_storage_account.sa.name}"
  container_access_type = "private"
}

resource "azurerm_key_vault" "vault" {
  name                = "sdp${var.project=="sdp"?"":var.project}-vault"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  sku {
    name = "standard"
  }

  tenant_id = "${var.tenant_id}"

  enabled_for_disk_encryption = true
}

locals {
  users = "${distinct(concat(var.owners, var.admins))}"
  em = "49cb0410-986f-4d77-af2d-d4b48d35f0fd"
}

resource "azurerm_key_vault_access_policy" "vault-access" {
  vault_name          = "${azurerm_key_vault.vault.name}"
  resource_group_name = "${azurerm_key_vault.vault.resource_group_name}"

  tenant_id = "${azurerm_key_vault.vault.tenant_id}"
  object_id = "${element(local.users, count.index)}"

  key_permissions     = []

  // 1. only owners are allowed to retrieve
  // 2. all specified users can list
  // 3. only Environment management can set new ecrets
  secret_permissions = "${compact(list(
    contains(var.owners, element(local.users, count.index)) ? "get" : "",
    "list",
    element(local.users, count.index) == local.em ? "set" : ""
    ))}"

  count = "${length(local.users)}"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.project}-common-vnet"
  address_space       = ["10.3.0.0/16"]
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
}

resource "azurerm_subnet" "defaultsubnet" {
  name                 = "default"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "10.3.0.0/16"

  # Bug: specify the azure full id
  network_security_group_id = "/subscriptions/dd10eed9-865c-4bfa-a260-d3e8fe16b047/resourceGroups/sdp-common/providers/Microsoft.Network/networkSecurityGroups/${module.firewall.name}"
}

module "firewall" {
  source              = "../firewall"
  environment         = "common"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  ip_whitelist        = "${var.ip_whitelist}"
}

# Jumpbox for Oozie deployments On Premise -> HDInsight
module "jumpbox" {
  source              = "../vm"
  environment         = "common"
  vmname              = "vm-common-jump"
  vmsize              = "Basic_A0"
  role                = "jumpbox"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  subnet_id           = "${azurerm_subnet.defaultsubnet.id}"
  auto_start_stop     = "no"
  managed_disk_type   = "Standard_LRS"
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