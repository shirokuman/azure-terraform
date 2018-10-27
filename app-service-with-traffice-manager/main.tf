# Proviers
provider "azurerm" {}

# Variables

# Local Values
locals {
  resource_group_name   = "tfrm-rg"
  web_app_locations       = ["japanwest", "japaneast"]
  app_service_plan_name = "tfrm-pln"
  web_app_name          = "tfrm-app"
  traffic_manager_profile_name = "tfrm-dns-lb"
}

# Resources
resource "azurerm_resource_group" "rg" {
  name     = "${substr(local.locations[count.index], 5, 1)}-${local.resource_group_name}" # japanwest => w, japaneast => e
  location = "${local.locations[count.index]}"
  count    = "${length(local.locations)}"
}

resource "azurerm_traffic_manager_profile" "profile" {
  name                   = "${local.traffic_manager_profile_name}"
  resource_group_name    = "${azurerm_resource_group.rg.name}"
  traffic_routing_method = "Priority"

  dns_config {
    relative_name = "${local.traffic_manager_profile_name}"
    ttl           = 30
  }

  monitor_config {
    protocol = "http"
    port     = 80
    path     = "/"
  }
}

resource "azurerm_traffic_manager_endpoint" "endpoint" {
  name                = "endpoint${count.index}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  profile_name        = "${azurerm_traffic_manager_profile.profile.name}"
  target_resource_id  = "${element(azurerm_app_service.app.*.id, count.index)}"
  endpoint_status     = "Enabled"
  type                = "azureEndpoints"
  count               = 2
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
