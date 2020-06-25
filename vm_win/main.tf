locals {
  admin_username = "sdp-admin"
  admin_password = "m<7$TMFKuMXc"
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "${var.vmname}-publicip"
    location                     = "${var.location}"
    resource_group_name          = "${var.resource_group_name}"
    public_ip_address_allocation = "static"
}

# Create primary network interface (which includes a public ip)
resource "azurerm_network_interface" "myterraformnic" {
  name                      = "${var.vmname}-nic"
  location                  = "${var.location}"
  resource_group_name       = "${var.resource_group_name}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.myterraformpublicip.id}"
  }
}

# Create any additional NICs in other subnets
resource "azurerm_network_interface" "additional-nic" {
    name                      = "${var.vmname}-${element(split("/", element(var.additional_subnet_ids, count.index)), length(split("/", element(var.additional_subnet_ids, count.index)))-1)}-nic"
    location                  = "${var.location}"
    resource_group_name       = "${var.resource_group_name}"

    ip_configuration {
        name                          = "ipconfig1"
        subnet_id                     = "${element(var.additional_subnet_ids, count.index)}"
        private_ip_address_allocation = "dynamic"
    }

    count = "${length(var.additional_subnet_ids)}"
}

resource "azurerm_managed_disk" "additional-disk" {
    name                    = "${var.vmname}-data-disk"
    location                = "${var.location}"
    resource_group_name     = "${var.resource_group_name}"
    storage_account_type    = "Standard_LRS"
    create_option           = "Empty"
    disk_size_gb            = "${var.additional_disk_size}"
}

# Create virtual machine
resource "azurerm_virtual_machine" "myterraformvm" {
    name                  = "${var.vmname}"
    location              = "${var.location}"
    resource_group_name   = "${var.resource_group_name}"
    network_interface_ids = ["${concat(list(azurerm_network_interface.myterraformnic.id), azurerm_network_interface.additional-nic.*.id)}"]
    vm_size               = "${var.vmsize}"

    storage_os_disk {
        name              = "${var.vmname}-disk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "${var.managed_disk_type}"
    }

    storage_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "${var.os_sku}"
        version   = "latest"
    }

    storage_data_disk {
        name              = "${var.vmname}-data-disk"
        managed_disk_id   = "${azurerm_managed_disk.additional-disk.id}"
        managed_disk_type = "Standard_LRS"
        disk_size_gb      = "${var.additional_disk_size}"
        create_option     = "Attach"
        lun               = "0"
    }

    primary_network_interface_id = "${azurerm_network_interface.myterraformnic.id}"

    os_profile {
        computer_name  = "${var.vmname}"
        admin_username = "${local.admin_username}"
        admin_password = "${local.admin_password}"
    }

    os_profile_windows_config {
    }

    boot_diagnostics {
        enabled = false
        storage_uri = "https://sdpcommon.blob.core.windows.net"
    }

    tags = "${merge(map("role", var.role, "auto_start_stop", var.auto_start_stop, "project", var.projekt, "environment", var.environment), var.tags)}"
}
