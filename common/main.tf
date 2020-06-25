
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

output "resource_group_name" {
  value = "${azurerm_resource_group.rg.name}"
}
