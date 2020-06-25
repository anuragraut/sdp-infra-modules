
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.project}-${var.environment}-nsg"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
}

resource "azurerm_network_security_rule" "defaultAllowSSH" {
  name                        = "AllowSSHInBound"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = "${values(var.ip_whitelist)}"
  destination_address_prefix  = "*"
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.nsg.name}"
}

resource "azurerm_network_security_rule" "allowAzureHealth" {
  name                        = "allowAzureHealthAndManagementServices"
  priority                    = 1002
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefixes     = ["168.61.49.99", "23.99.5.239", "168.61.48.131", "138.91.141.162", "52.166.243.90", "52.174.36.244","168.63.129.16"]
  destination_address_prefix  = "*"
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.nsg.name}"
}

resource "azurerm_network_security_rule" "allowIncomingSSL" {
  name                        = "allowIncomingSSL"
  priority                    = 1003
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefixes     = "${values(var.ip_whitelist)}"
  destination_address_prefix  = "*"
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.nsg.name}"
}

output "name" {
  value = "${azurerm_network_security_group.nsg.name}"
}

output "id" {
  value = "${azurerm_network_security_group.nsg.id}"
}
