
resource "azurerm_resource_group" "rg" {
    name     = "${var.project}-${var.name}${var.type}-rg"
    location = "West Europe"
}

resource "azurerm_automation_account" "account" {
  name                = "${var.project}-${var.name}${var.type}-automation"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  sku {
    name = "Basic"
  }
}
