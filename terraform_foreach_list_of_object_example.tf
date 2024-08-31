provider "azurerm" {
  features {}
  subscription_id = "9exxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}

variable "resource_group" {
  type = list(object({
    environment = string
    name        = string
    location    = string
  }))
  default = [{
    environment = "dev"
    name        = "dev_rg"
    location    = "East US"
  }]
}

resource "azurerm_resource_group" "dev" {
  for_each = { for sa in var.resource_group : sa.name => sa if sa.environment == "dev" }
  name     = each.value.name
  location = each.value.location
}

resource "azurerm_resource_group" "prod" {
  for_each = { for sa in var.resource_group : sa.name => sa if sa.environment == "prod" }
  name     = each.value.name
  location = each.value.location
}