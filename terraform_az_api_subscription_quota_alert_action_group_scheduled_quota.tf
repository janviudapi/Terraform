terraform {
  required_providers {
    azapi = {
      source = "azure/azapi"
      # version = "1.8.0"  # Use the latest version or whichever is stable
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "azapi" {
  # Optionally configure provider settings here
}

provider "azurerm" {
  features {}
  subscription_id = "9exxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}

###########################################################

variable "resource_group_name" {
  description = "Resource Group Name"
  type        = string
  default     = "vcloud-lab.com"
}

variable "action_group_name" {
  description = "The name of the action group"
  type        = string
  default     = "Action_Group_01"
}

variable "action_group_short_name" {
  description = "The short name of the action group"
  type        = string
  default     = "AG01"
}

variable "email_address" {
  description = "The email address to use for email alerts"
  type        = string
  default     = "thecloudcurry@gmail.com"
}

variable "quota_alert_name" {
  description = "Provide Quota alert name"
  type        = string
  default     = "quota_alert_01"
}

variable "dimensions_type" {
  type        = string
  description = "Provide Dimensions Type for Scheduled Query Rule"
  default     = "microsoft.compute/locations/usages"
}

variable "dimensions_quota_name" {
  type        = string
  description = "Provide Dimensions name for Scheduled Query Rule"
  default     = "cores"
}

######################################################

data "azurerm_subscription" "subscriptioninfo" {}

data "azurerm_resource_group" "rginfo" {
  name = var.resource_group_name
}

data "azurerm_user_assigned_identity" "uaiinfo" {
  name                = "dev"
  resource_group_name = data.azurerm_resource_group.rginfo.name
}

######################################################

locals {
  scopeInfo = "/subscriptions/${data.azurerm_subscription.subscriptioninfo.subscription_id}"
  # format("%s/%s","/subscriptions/","data.azurerm_subscription.subscriptioninfo.subscription_id)
}

######################################################

#https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/actiongroups?pivots=deployment-language-terraform

resource "azapi_resource" "action_group" {
  type      = "Microsoft.Insights/actionGroups@2023-09-01-preview"
  name      = var.action_group_name
  location  = "Global"
  parent_id = data.azurerm_resource_group.rginfo.id

  body = jsonencode({
    properties = {
      groupShortName = var.action_group_short_name
      enabled        = true

      emailReceivers = [
        {
          name                 = "EmailAction"
          emailAddress         = var.email_address
          useCommonAlertSchema = true
        }
      ]

      smsReceivers               = []
      webhookReceivers           = []
      eventHubReceivers          = []
      itsmReceivers              = []
      azureAppPushReceivers      = []
      automationRunbookReceivers = []
      voiceReceivers             = []
      logicAppReceivers          = []
      azureFunctionReceivers     = []

      armRoleReceivers = [
        {
          name                 = "EmailARMRole"
          roleId               = "8e3af657-a8ff-443c-a75c-2fe8c4bcb635"
          useCommonAlertSchema = true
        }
      ]
    }
  })
}

# https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/scheduledqueryrules?pivots=deployment-language-terraform


resource "azapi_resource" "scheduled_query_rule" {
  type      = "Microsoft.Insights/scheduledqueryrules@2023-03-15-preview"
  name      = var.quota_alert_name
  location  = data.azurerm_resource_group.rginfo.location
  parent_id = data.azurerm_resource_group.rginfo.id

  identity {
    type         = "UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.uaiinfo.id]
  }

  body = jsonencode({
    properties = {
      severity            = 4
      enabled             = true
      evaluationFrequency = "PT15M"
      scopes              = [local.scopeInfo]
      windowSize          = "PT15M"

      criteria = {
        allOf = [
          {
            query               = format("arg('').QuotaResources | where subscriptionId =~ '%s' | where type =~ 'microsoft.compute/locations/usages' | where isnotempty(properties) | mv-expand propertyJson = properties.value limit 400 | extend usage = propertyJson.currentValue, quota = propertyJson['limit'], quotaName = tostring(propertyJson['name'].value) | extend usagePercent = toint(usage)*100 / toint(quota) | project-away properties | where location in~ ('%s') | where quotaName in~ ('%s')", data.azurerm_subscription.subscriptioninfo.subscription_id, data.azurerm_resource_group.rginfo.location, var.dimensions_quota_name)
            timeAggregation     = "Maximum"
            metricMeasureColumn = "usagePercent"

            # Dimensions Configuration
            dimensions = [
              {
                name     = "type"
                operator = "Include"
                values   = [var.dimensions_type]
              },
              {
                name     = "location"
                operator = "Include"
                values   = [data.azurerm_resource_group.rginfo.location]
              },
              {
                name     = "quotaName"
                operator = "Include"
                values   = [var.dimensions_quota_name]
              }
            ]

            operator  = "GreaterThanOrEqual"
            threshold = 80

            failingPeriods = {
              numberOfEvaluationPeriods = 1
              minFailingPeriodsToAlert  = 1
            }
          }
        ]
      }

      actions = {
        actionGroups = [azapi_resource.action_group.id]
      }
    }
  })
}

output "name" {
  value = azapi_resource.action_group.id
}