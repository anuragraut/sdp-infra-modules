
locals {
  admin_username = "sdp-admin"
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
        publisher = "OpenLogic"
        offer     = "CentOS"
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
    }

    # Give it by default the Ansible @ Jenkins public key
    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/${local.admin_username}/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDebVjdxnlo0V88Ws20mXYJgeAjGIE44Bsypz7/SK6LFIT2HEpZIV48SIwDW4q54oxwCaXb3V+tYGc2YgI/ie80JS5QFjlRqGudIQ3V0ckLRjhFOTMceMUWHvwaeOfCJAWvFt1kma3DMc6PNqWPnQoF6ySQ8E241eXobSAo55mHffyUkUAMjxsPKj1Co8Uxikc+689D+b3vvnsECA+lK0j+UWU/LA6pb616avWVWSAHSdZ8vAftcVPDbWym92ku5R+hET8mvMJhQ4N9GYKWoNbGTLzUq5903LqgYp3yZ4ChwSpqHUIgQCtkubi9X76Pw+G3lpyBnzyyhLBwf3MutKDnv0MItjPRPbhTdrPWUykDppE8Zw6WQg0QsjRFc6CJn8fsghYivqDrB5ELpyMvu0mnmG5StF0EDgu2OdsO/Fe4gl7jjKhNuft3O8oqiK/RZJqzR1UMQNL9+BmcG8hqscooDXbuNawP2bG8YJTkwNm7tNCOzbL4UcU0HJrzJNynjErcK1XT/cJMGZtOdmj8AfP06Xmdnyz8p1Q/v2Z6oq1hKkgsBm8AuGakgh+trksJrWdSdghbrbtcuJmeuvcG+eWLAvv/gSF/CZD9Fp03Q6U8x7XbID0MWQBg0mBR7Mr6SeuYnmvUui/qWOWKTL01Fw107B6NEa3qcYjVWB7rSs+o8Q== ansible@vm-dev-jenkins01"
        }
    }

    boot_diagnostics {
        enabled = false
        storage_uri = "https://sdpcommon.blob.core.windows.net"
    }

    tags = "${merge(map("role", var.role, "auto_start_stop", var.auto_start_stop, "project", var.projekt, "environment", var.environment), var.tags)}"
}
