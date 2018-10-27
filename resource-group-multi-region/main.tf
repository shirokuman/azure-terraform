# Proviers
provider "azurerm" {}

# Variables

# Local Values
locals {
  resource_group_name = "tfrm-rg"
  locations           = ["japanwest", "japaneast"]
}

# Resources
resource "azurerm_resource_group" "rg" {
  name     = "${substr(local.locations[count.index], 5, 1)}-${local.resource_group_name}" # japanwest => w, japaneast => e
  location = "${local.locations[count.index]}"
  count    = "${length(local.locations)}"
}
