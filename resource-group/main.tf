# Proviers
provider "azurerm" {}

# Variables

# Local Values
locals {
  resource_group_name = "w-tfrm-rg"
  location            = "japanwest"
}

# Resources
resource "azurerm_resource_group" "rg" {
  name     = "${local.resource_group_name}"
  location = "${local.location}"
}
