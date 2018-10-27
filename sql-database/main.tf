# Proviers
provider "azurerm" {}

# Variables
variable "sql_login" {}
variable "sql_password" {}

# Local Values
locals {
  resource_group_name              = "w-tfrm-rg"
  location                         = "japanwest"
  sql_server_name                  = "w-tfrm-sql"
  database_name                    = "MyDatabase"
  edition                          = "Basic"      # Basic/Standard/Premium
  max_size_bytes                   = "2147483648" # 2gb
  requested_service_objective_name = "Basic"      # Basic/S0,S1,S2,S3,S4,S6,S7,S9,S12/P1,P2,P4,P6,P11,P15
}

# Resources
resource "azurerm_resource_group" "rg" {
  name     = "${local.resource_group_name}"
  location = "${local.location}"
}

resource "azurerm_sql_server" "server" {
  name                         = "${local.sql_server_name}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  location                     = "${azurerm_resource_group.rg.location}"
  version                      = "12.0"
  administrator_login          = "${var.sql_login}"
  administrator_login_password = "${var.sql_password}"
}

resource "azurerm_sql_firewall_rule" "fw" {
  name                = "AllowAllWindowsAzureIps"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  server_name         = "${azurerm_sql_server.server.name}"
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_sql_database" "db" {
  name                             = "${local.database_name}"
  resource_group_name              = "${azurerm_resource_group.rg.name}"
  location                         = "${azurerm_resource_group.rg.location}"
  collation                        = "JAPANESE_CI_AS"
  edition                          = "${local.edition}"
  max_size_bytes                   = "${local.max_size_bytes}"
  requested_service_objective_name = "${local.requested_service_objective_name}"
  server_name                      = "${azurerm_sql_server.server.name}"
}

output "sql_server_fqdn" {
  value = "${azurerm_sql_server.server.fully_qualified_domain_name}"
}
