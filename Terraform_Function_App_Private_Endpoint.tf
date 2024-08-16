provider "azurerm" {
  features {}
}

######################################

variable "resource_group_name" {
  default = "dev"
}

variable "virtual_network" {
  default = "vcloud-lab-dev"
}

variable "subnet" {
  default = "default"
}

variable "private_dns_zone" {
  default = "privatelink.azurewebsites.net"
}

variable "user_assigned_identity" {
  default = "vcloudlabuser"
}

variable "private_dns_zone_virtual_network_link" {
  default = "vcloud-lab-dev-privatelink"
}

####

variable "storage_account_name" {
  default = "vcloudlabsa"
}

variable "app_service_plan" {
  default = "vcloudlabasp"
}

####

variable "function_app" {
  default = "vcloudlabafa"
}

variable "application_stack" {
  type = map(any)
  default = {
    dotnet_version = null
    #use_dotnet_isolated_runtime = false
    java_version            = null
    node_version            = null
    python_version          = 3.9
    powershell_core_version = null
    #use_custom_runtime = false
  }
  validation {
    condition = length([for stack_name, stack_value in var.application_stack : stack_name if(stack_value != null)]) == 1
    #(&& stack_name != "use_dotnet_isolated_runtime" && stack_name != "use_custom_runtime" && stack_value != null)
    #(stack_name != "use_dotnet_isolated_runtime" && stack_name != "use_custom_runtime" && stack_value != "") #when value is ""
    error_message = "Exactly one value in 'application_stack' must be non-null."
  }
}

variable "app_settings" {
  default = {
    "FUNCTIONS_WORKER_RUNTIME1" = "python3"
  }
}

variable "function_app_os" {
  default = "Linux"
}

variable "delegation_subnet" {
  default = "delegationsubnet"
}

variable "delegation_subnet_address_prefixes" {
  type = list(string)
  default = ["10.0.1.0/24"]
}

######################################

data "azurerm_resource_group" "rg_info" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "vnet_info" {
  name                = var.virtual_network
  resource_group_name = data.azurerm_resource_group.rg_info.name
}

data "azurerm_subnet" "subnet_info" {
  name                 = var.subnet
  virtual_network_name = data.azurerm_virtual_network.vnet_info.name
  resource_group_name  = data.azurerm_resource_group.rg_info.name
}

data "azurerm_private_dns_zone" "pdz" {
  name                = var.private_dns_zone
  resource_group_name = data.azurerm_resource_group.rg_info.name
}

data "azurerm_user_assigned_identity" "uai" {
  name                = var.user_assigned_identity
  resource_group_name = data.azurerm_resource_group.rg_info.name
}

data "azurerm_private_dns_zone_virtual_network_link" "pdzvnl" {
  name                  = var.private_dns_zone_virtual_network_link
  resource_group_name   = data.azurerm_resource_group.rg_info.name
  private_dns_zone_name = data.azurerm_private_dns_zone.pdz.name
}

#######################################

resource "azurerm_storage_account" "sa" {
  name                     = var.storage_account_name
  resource_group_name      = data.azurerm_resource_group.rg_info.name
  location                 = data.azurerm_resource_group.rg_info.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "asp" {

  name                = var.app_service_plan
  resource_group_name = data.azurerm_resource_group.rg_info.name
  location            = data.azurerm_resource_group.rg_info.location
  os_type             = var.function_app_os
  sku_name            = "S1"
}

resource "azurerm_linux_function_app" "lfa" {
  name                 = var.function_app
  location             = data.azurerm_resource_group.rg_info.location
  resource_group_name  = data.azurerm_resource_group.rg_info.name
  service_plan_id      = azurerm_service_plan.asp.id
  storage_account_name = azurerm_storage_account.sa.name
  #storage_account_access_key    = azurerm_storage_account.sa.primary_access_key   #When using system managed identity
  storage_uses_managed_identity = true #When using user managed identity
  public_network_access_enabled = false

  #tags = var.tags

  app_settings = merge(
    var.app_settings,
    {
      "FUNCTIONS_WORKER_RUNTIME" = "python"
    }
  )

  site_config {
    application_stack {
      dotnet_version = var.application_stack["dotnet_version"]
      #use_dotnet_isolated_runtime = var.application_stack["use_dotnet_isolated_runtime"]
      java_version            = var.application_stack["java_version"]
      node_version            = var.application_stack["node_version"]
      python_version          = var.application_stack["python_version"]
      powershell_core_version = var.application_stack["powershell_core_version"]
      #use_custom_runtime          = var.application_stack["use_custom_runtime"]
    }
  }

  identity {
    type         = "UserAssigned" #When using user managed identity to access storage account / or use systemassigned
    identity_ids = [data.azurerm_user_assigned_identity.uai.id]
  }
}

### User mananged Privileges to storage account 

resource "azurerm_role_assignment" "sac" {
  scope                = azurerm_storage_account.sa.id
  principal_id         = data.azurerm_user_assigned_identity.uai.principal_id
  role_definition_name = "Storage Account Contributor"
}

resource "azurerm_role_assignment" "sbc" {
  scope                = azurerm_storage_account.sa.id
  principal_id         = data.azurerm_user_assigned_identity.uai.principal_id
  role_definition_name = "Storage Blob Data Contributor"
}

# if required
resource "azurerm_role_assignment" "sfdssc" {
  scope                = azurerm_storage_account.sa.id
  principal_id         = data.azurerm_user_assigned_identity.uai.principal_id
  role_definition_name = "Storage File Data SMB Share Contributor"
}

# resource "azurerm_private_dns_zone_virtual_network_link" "pdzvnl" {
#   name                  = "${resource.azurerm_linux_function_app.lfa.name}-private-link"
#   resource_group_name   = data.azurerm_resource_group.rg_info.name
#   private_dns_zone_name = data.azurerm_private_dns_zone.pdz.name
#   virtual_network_id    = data.azurerm_virtual_network.vnet_info.id
#   registration_enabled  = true
# }

resource "azurerm_private_endpoint" "sites_private_endpoint" {
  name                = "${resource.azurerm_linux_function_app.lfa.name}-ep"
  resource_group_name = data.azurerm_resource_group.rg_info.name
  location            = data.azurerm_resource_group.rg_info.location
  subnet_id           = data.azurerm_subnet.subnet_info.id

  private_service_connection {
    name                           = "${resource.azurerm_linux_function_app.lfa.name}-ep-connection"
    private_connection_resource_id = resource.azurerm_linux_function_app.lfa.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${resource.azurerm_linux_function_app.lfa.name}-dnz-zone-group"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.pdz.id]
  }
}

##############

#For outbound calls to other services, subnet should have delegation access
resource "azurerm_subnet" "delegation_subnet" {
  name                 = var.delegation_subnet
  virtual_network_name = data.azurerm_virtual_network.vnet_info.name
  resource_group_name  = data.azurerm_resource_group.rg_info.name
  address_prefixes     = var.delegation_subnet_address_prefixes
  delegation {
    name = "web-serverfarm"

    service_delegation {
      name = "Microsoft.Web/serverFarms"
      #actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
    }
  }
}

#For outbound calls to other services, subnet should have delegation access
resource "azurerm_app_service_virtual_network_swift_connection" "apsvnsc" {
  app_service_id = azurerm_linux_function_app.lfa.id
  subnet_id      = resource.azurerm_subnet.delegation_subnet.id
}

##############

output "application_stack" {
  value     = resource.azurerm_linux_function_app.lfa.site_config[0].application_stack[0] #.node_version
  sensitive = false
}

output "app_settings" {
  value     = resource.azurerm_linux_function_app.lfa.app_settings
  sensitive = false
}