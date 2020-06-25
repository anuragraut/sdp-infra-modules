
resource "azurerm_virtual_network_peering" "peer-src-to-dst" {
  name = "${element(split("/", var.src), 8)}-to-${element(split("/", var.dst), 8)}"
  resource_group_name = "${element(split("/", var.src), 4)}"
  virtual_network_name = "${element(split("/", var.src), 8)}"
  remote_virtual_network_id = "${var.dst}"
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "peer-dst-to-src" {
  name = "${element(split("/", var.dst), 8)}-to-${element(split("/", var.src), 8)}"
  resource_group_name = "${element(split("/", var.dst), 4)}"
  virtual_network_name = "${element(split("/", var.dst), 8)}"
  remote_virtual_network_id = "${var.src}"
  allow_virtual_network_access = true
}

