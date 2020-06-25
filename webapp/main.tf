resource "azurerm_resource_group" "rg" {
  name     = "${var.project}-${var.type}-${var.name}-rg"
  location = "${var.location}"
}

resource "azurerm_app_service_plan" "sp" {
  name                = "${var.project}-${var.type}-${var.name}-sp"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  sku {
    tier = "${var.sku_tier}"
    size = "${var.sku_size}"
  }
}

resource "azurerm_app_service" "app" {
  name                = "${var.project}-${var.type}-${var.name}-app"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  app_service_plan_id = "${azurerm_app_service_plan.sp.name}"

  site_config {
    python_version         = "${var.language_version}"
    scm_type               = "${var.scm_type}"
  }
}
