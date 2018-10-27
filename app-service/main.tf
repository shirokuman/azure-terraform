# Proviers
provider "azurerm" {}

# Variables

# Local Values
locals {
  resource_group_name   = "w-tfrm-rg"
  location              = "japanwest"
  app_service_plan_name = "w-tfrm-pln"
  web_app_name          = "w-tfrm-app"
}

# Resources
resource "azurerm_resource_group" "rg" {
  name     = "${local.resource_group_name}"
  location = "${local.location}"
}

resource "azurerm_app_service_plan" "plan" {
  name                = "${local.app_service_plan_name}"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  sku {
    tier = "Free"
    size = "F1"
  }
}

resource "azurerm_app_service" "app" {
  name                = "${local.web_app_name}-${count.index+1}"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  app_service_plan_id = "${azurerm_app_service_plan.plan.id}"
  count               = 2

  site_config {
    dotnet_framework_version  = "v4.0"
    scm_type                  = "LocalGit"
    use_32_bit_worker_process = true
  }
}
