
resource "azurerm_virtual_network_peering" "peer" {
  name = "${element(split("/", element(var.src, count.index)), length(split("/", element(var.src, count.index)))-1)}-to-${element(split("/", var.dst), 8)}"
  resource_group_name = "${element(split("/", element(var.src, count.index)), 4)}"
  virtual_network_name = "${element(split("/", element(var.src, count.index)), 8)}"
  remote_virtual_network_id = "${var.dst}"
  allow_virtual_network_access = true
  count = "${length(var.src)}"
}
