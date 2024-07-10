terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      #version = "=2.91.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

variable "resource_group" {
  type        = string
  default     = "vcloud-lab.com"
  description = "Azure Virtual Network"
}

variable "virtual_network" {
  type        = string
  default     = "vcloud_lab_global_vnet01"
  description = "Azure Virtual Network"
}

variable "subnets" {
  type = map(object({
    address_prefix = string
  }))
  default = {
    subnet-1 = { address_prefix = "10.0.1.0/24" }
    subnet-2 = { address_prefix = "10.0.2.0/24" }
    subnet-3 = { address_prefix = "10.0.3.0/24" }
  }
  description = "vNet Subnet list"
}

data "azurerm_resource_group" "rginfo" {
  name = var.resource_group
}

data "azurerm_virtual_network" "vnetinfo" {
  name                = var.virtual_network
  resource_group_name = data.azurerm_resource_group.rginfo.name
}

resource "azurerm_subnet" "name" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = data.azurerm_resource_group.rginfo.name
  virtual_network_name = data.azurerm_virtual_network.vnetinfo.name
  address_prefixes     = [each.value.address_prefix]
}

output "subnet_ids" {
  value = { for k, v in azurerm_subnet.name : k => v.id }
}