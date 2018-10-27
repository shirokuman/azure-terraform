# Proviers
provider "azurerm" {}

# Variables

# Local Values
locals {
  resource_group_name = "w-tfrm-rg"
  location            = "japanwest"
  nsg_name            = "w-arm-nsg"
  rule_name           = "Allow-Inbound-RDP-Internet"
}

# Resources
resource "azurerm_resource_group" "rg" {
  name     = "${local.resource_group_name}"
  location = "${local.location}"
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

