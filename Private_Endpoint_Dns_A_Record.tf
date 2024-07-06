terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      #version = "=2.91.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "rginfo" {
  name                = "vcloud-lab.com"
}

data "azurerm_virtual_network" "vnetinfo" {
  name                = "vcloud_lab_global_vnet01"
  resource_group_name = data.azurerm_resource_group.rginfo.name
}

data "azurerm_subnet" "subnetinfo" {
  name                 = "default"
  resource_group_name  = data.azurerm_resource_group.rginfo.name
  virtual_network_name = data.azurerm_virtual_network.vnetinfo.name
}

data "azurerm_private_dns_zone" "privatednszoneinfo" {
  name                = "vcloud-lab.com"
  resource_group_name = data.azurerm_resource_group.rginfo.name
}

data "azurerm_storage_account" "storageaccountinfo" {
  name                = "vcloudlabdemo01"
  resource_group_name = data.azurerm_resource_group.rginfo.name
}

resource "azurerm_private_endpoint" "privateendpoint" {
  name                = "vcloud-lab-endpoint"
  resource_group_name = data.azurerm_resource_group.rginfo.name
  location            = data.azurerm_resource_group.rginfo.location
  subnet_id           = data.azurerm_subnet.subnetinfo.id

  private_service_connection {
    name                           = "privateendpointserviceconnection"
    private_connection_resource_id = data.azurerm_storage_account.storageaccountinfo.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "privateendpointdnzzonegroup"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.privatednszoneinfo.id]
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "networklink" {
  name                  = "privatednsnetworklink"
  resource_group_name   = data.azurerm_resource_group.rginfo.name
  private_dns_zone_name = data.azurerm_private_dns_zone.privatednszoneinfo.name
  virtual_network_id    = data.azurerm_virtual_network.vnetinfo.id
}

resource "azurerm_private_dns_a_record" "private_dns_a_record" {
  name                = data.azurerm_storage_account.storageaccountinfo.name
  zone_name           = data.azurerm_private_dns_zone.privatednszoneinfo.name
  resource_group_name = data.azurerm_resource_group.rginfo.name
  ttl                 = 300
  records             = [resource.azurerm_private_endpoint.privateendpoint.private_service_connection[0].private_ip_address]
}

output "name" {
  value = resource.azurerm_private_endpoint.privateendpoint.private_service_connection[0].private_ip_address
}
