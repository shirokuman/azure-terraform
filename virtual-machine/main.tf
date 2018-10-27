# Proviers
provider "azurerm" {}

# Variables
variable "admin_username" {}
variable "admin_password" {}

# Local Values
locals {
  resource_group_name = "w-tfrm-rg"
  location            = "japanwest"
  prefix              = "w-tfrm"
  vm_name             = "${local.prefix}-vm"
  os_disk_type        = "Standard_LRS"
  os_disk_name        = "${local.vm_name}-os-disk"
  vm_size             = "Standard_B1ms"
  pip_name            = "${local.vm_name}-pip"
  nic_name            = "${local.vm_name}-nic"
  vnet_name           = "${local.prefix}-vnet"
  vnet_prefix         = "192.168.1.0/24"
  subnet1_Name        = "subnet1"
  nsg_name            = "${local.prefix}-nsg"
  rule_name           = "Allow-Inbound-RDP-Internet"
}

# Resources
resource "azurerm_resource_group" "rg" {
  name     = "${local.resource_group_name}"
  location = "${local.location}"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${local.vnet_name}"
  location            = "${local.location}"
  address_space       = ["${local.vnet_prefix}"]
  resource_group_name = "${azurerm_resource_group.rg.name}"
}

resource "azurerm_subnet" "subnet" {
  name                 = "${local.subnet1_Name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  address_prefix       = "${cidrsubnet(local.vnet_prefix, 3, 6)}" # 192.168.1.192/27
}

resource "azurerm_network_interface" "nic" {
  name                = "${local.nic_name}"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.pip.id}"
  }
}

resource "azurerm_public_ip" "pip" {
  name                = "${local.pip_name}"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  public_ip_address_allocation = "Dynamic"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${local.nsg_name}"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  security_rule {
    name                       = "${local.rule_name}"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "assoc" {
  subnet_id                 = "${azurerm_subnet.subnet.id}"
  network_security_group_id = "${azurerm_network_security_group.nsg.id}"
}

resource "azurerm_virtual_machine" "vm" {
  name                  = "${local.vm_name}"
  location              = "${azurerm_resource_group.rg.location}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  network_interface_ids = ["${azurerm_network_interface.nic.id}"]
  vm_size               = "${local.vm_size}"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${local.os_disk_name}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "${local.os_disk_type}"
  }

  os_profile {
    computer_name  = "${local.vm_name}"
    admin_username = "${var.admin_username}"
    admin_password = "${var.admin_password}"
  }

  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = true
    timezone                  = "Tokyo Standard Time"
  }
}
