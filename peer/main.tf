
resource "azurerm_virtual_network_peering" "peer-src-to-dst" {
  name = "${lookup(var.src, "name")}-to-${lookup(var.dst, "name")}"
  resource_group_name = "${lookup(var.src, "rg")}"
  virtual_network_name = "${lookup(var.src, "name")}"
  remote_virtual_network_id = "/subscriptions/${lookup(var.dst, "subscription")}/resourceGroups/${lookup(var.dst, "rg")}/providers/Microsoft.Network/virtualNetworks/${lookup(var.dst, "name")}"
  allow_virtual_network_access = true
  count = "${var.enabled ? 1 : 0}"
}

resource "azurerm_virtual_network_peering" "peer-dst-to-src" {
  name = "${lookup(var.dst, "name")}-to-${lookup(var.src, "name")}"
  resource_group_name = "${lookup(var.dst, "rg")}"
  virtual_network_name = "${lookup(var.dst, "name")}"
  remote_virtual_network_id = "/subscriptions/${lookup(var.src, "subscription")}/resourceGroups/${lookup(var.src, "rg")}/providers/Microsoft.Network/virtualNetworks/${lookup(var.src, "name")}"
  allow_virtual_network_access = true
  count = "${var.bidirectional && var.enabled ? 1 : 0}"
}
