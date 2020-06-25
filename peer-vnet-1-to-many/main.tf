
resource "azurerm_virtual_network_peering" "peer" {
  name = "${element(split("/", var.src), 8)}-to-${element(split("/", element(var.dst, count.index)), length(split("/", element(var.dst, count.index)))-1)}"
  resource_group_name = "${element(split("/", var.src), 4)}"
  virtual_network_name = "${element(split("/", var.src), 8)}"
  remote_virtual_network_id = "${element(var.dst, count.index)}"
  allow_virtual_network_access = true
  count = "${length(var.dst)}"
}
