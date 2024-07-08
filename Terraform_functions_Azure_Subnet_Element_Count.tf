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
  type        = list(any)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
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
  count                = length(var.subnets)
  name                 = "subnet-${sum([count.index, 1])}" #
  resource_group_name  = data.azurerm_resource_group.rginfo.name
  virtual_network_name = data.azurerm_virtual_network.vnetinfo.name
  address_prefixes     = ["${element(var.subnets, count.index)}"]
}