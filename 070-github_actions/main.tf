provider "azurerm" {
  features {}
}

##################

variable "subnet" {
  type = object({
    name                 = string
    resource_group_name  = string
    virtual_network_name = string
    address_prefixes     = list(string)
  })
  default = {
    name                 = "subnet1"
    resource_group_name  = "dev"
    virtual_network_name = "dev-vnet"
    address_prefixes     = ["10.0.1.0/24"]
  }
}

##################

resource "azurerm_subnet" "subnet" {
  name          = var.subnet.name
  resource_group_name  = var.subnet.resource_group_name
  virtual_network_name = var.subnet.virtual_network_name
  address_prefixes     = var.subnet.address_prefixes
}

##################

output "subnet_id" {
  value = resource.azurerm_subnet.subnet.id
}