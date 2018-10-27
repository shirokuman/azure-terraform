# Proviers
provider "azurerm" {}

# Variables

# Local Values
locals {
  resource_group_name      = "w-tfrm-rg"
  location                 = "japanwest"
  storage_account_name     = "wtfrmstorage"
  storage_account_tier     = "Standard"
  storage_replication_type = "LRS"
}

# Resources
resource "random_integer" "num" {
  min = 10000
  max = 99999
}

resource "azurerm_resource_group" "rg" {
  name     = "${local.resource_group_name}"
  location = "${local.location}"
}

resource "azurerm_storage_account" "str" {
  name                     = "${local.storage_account_name}${random_integer.num.result}"
  resource_group_name      = "${azurerm_resource_group.rg.name}"
  location                 = "${azurerm_resource_group.rg.location}"
  account_tier             = "${local.storage_account_tier}"
  account_replication_type = "${local.storage_replication_type}"
}
