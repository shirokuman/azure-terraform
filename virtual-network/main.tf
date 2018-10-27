# Proviers
provider "azurerm" {}

# Variables
variable "clientRootCertName" {
  description = "The name of the client root certificate used to authenticate VPN clients. This is a common name used to identify the root cert."
}

variable "clientRootCertData" {
  description = "Client root certificate data used to authenticate VPN clients."
}

variable "revokedCertName" {
  description = "The name of revoked certificate, if any. This is a common name used to identify a given revoked certificate."
}

variable "revokedCertThumbprint" {
  description = "Thumbprint of the revoked certificate. This would revoke VPN client certificates matching this thumbprint from connecting to the VNet."
}

# Local Values
locals {
  resource_group_name           = "w-tfrm-rg"
  location                      = "japanwest"
  vnet_name                     = "w-arm-vnet"
  vnet_prefix                   = "192.168.1.0/24"
  subnet1_Name                  = "subnet1"
  subnet2_Name                  = "subnet2"
  gateway_name                  = "vnet-gateway"
  gateway_public_ip_name        = "gateway-pip"
  gateway_sku                   = "Basic"
  vpn_client_addressPool_prefix = "192.168.2.0/24"
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

resource "azurerm_subnet" "subnet1" {
  name                 = "${local.subnet1_Name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  address_prefix       = "${cidrsubnet(local.vnet_prefix, 1, 0)}" # 192.168.1.0/25
}

resource "azurerm_subnet" "subnet2" {
  name                 = "subnet2"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  address_prefix       = "${cidrsubnet(local.vnet_prefix, 2, 2)}" # 192.168.1.128/26
}

resource "azurerm_subnet" "gwsubnet" {
  name                 = "GatewaySubnet"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  address_prefix       = "${cidrsubnet(local.vnet_prefix, 4, 15)}" # 192.168.1.240/28
}

resource "azurerm_public_ip" "pip" {
  name                = "${local.gateway_public_ip_name}"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  public_ip_address_allocation = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "gateway" {
  name                = "${local.gateway_name}"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "${local.gateway_sku}"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = "${azurerm_public_ip.pip.id}"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = "${azurerm_subnet.gwsubnet.id}"
  }

  vpn_client_configuration {
    address_space = ["${local.vpn_client_addressPool_prefix}"]

    root_certificate {
      name             = "${var.clientRootCertName}"
      public_cert_data = "${var.clientRootCertData}"
    }

    revoked_certificate {
      name       = "${var.revokedCertName}"
      thumbprint = "${var.revokedCertThumbprint}"
    }
  }
}
