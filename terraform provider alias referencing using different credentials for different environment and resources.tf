provider "azurerm" {
  features {}
  alias           = "dev"
  client_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  client_secret   = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  tenant_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}

provider "azurerm" {
  features {}
  alias           = "prod"
  client_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  client_secret   = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  tenant_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}

locals {
  devEng  = "dev"
  prodEng = "prod"

  location                 = "East Us"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account" "dev" {
  provider = azurerm.dev

  name                     = "vcloudlabsa${local.devEng}"
  resource_group_name      = local.devEng
  location                 = local.location
  account_tier             = local.account_tier
  account_replication_type = local.account_replication_type
}

resource "azurerm_storage_account" "prod" {
  provider = azurerm.prod

  name                     = "vcloudlabsa${local.prodEng}"
  resource_group_name      = local.prodEng
  location                 = local.location
  account_tier             = local.account_tier
  account_replication_type = local.account_replication_type
}


/*
#Other alternatives and referencing implementations in Terraform
provider "aws" {
  alias  = "east"
  region = "us-east-1"
}

resource "aws_instance" "example" {
  provider = aws.east
  # ...
}

module "aws_vpc" {
  source = "./aws_vpc"
  providers = {
    aws = aws.east
  }
  # ...
}

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 3.0"
      configuration_aliases = [aws.alternate]
    }
  }
}
*/
