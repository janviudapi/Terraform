terraform {
  required_version = "1.9.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.4"
    }
  }
}

##################################

provider "azurerm" {
  features {}
  subscription_id = "9exxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}

##################################

locals {
  #case sensitive
  storagePrefix = "vcloudlabsa"
  containerName = "testcontainer"
  webAppPrefix  = "vcloudlabwa"
}

##################################

resource "azurerm_resource_group_template_deployment" "resources" {
  name                = "vcloud-lab.com"
  resource_group_name = "vcloud-lab.com"
  deployment_mode     = "Incremental"
  parameters_content = jsonencode({
    "storagePrefix" : {
      "value" : "vcloudlabsa"
    },
    "containerName" : {
      "value" : "testcontainer"
    },
    "webAppPrefix" : {
      "value" : "vcloudlabwa"
    }
  })
  template_content = <<TEMPLATE
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
      "storagePrefix": {
        "type": "string",
        "minLength": 3,
        "maxLength": 11
      },
      "storageSKU": {
        "type": "string",
        "defaultValue": "Standard_LRS",
        "allowedValues": [
          "Standard_LRS",
          "Standard_GRS",
          "Standard_RAGRS",
          "Standard_ZRS",
          "Premium_LRS",
          "Premium_ZRS",
          "Standard_GZRS",
          "Standard_RAGZRS"
        ]
      },
      "location": {
        "type": "string",
        "defaultValue": "[resourceGroup().location]"
      },
      "containerName": {
        "defaultValue": "test",
        "type": "String"
        },
      "appServicePlanName": {
        "type": "string",
        "defaultValue": "exampleplan"
      },
      "webAppPrefix": {
        "type": "string",
        "metadata": {
          "description": "Base name of the resource such as web app name and app service plan "
        },
        "minLength": 2
      },
      "linuxFxVersion": {
        "type": "string",
        "defaultValue": "php|7.0",
        "metadata": {
          "description": "The Runtime stack of current web app"
        }
      },
      "resourceTags": {
        "type": "object",
        "defaultValue": {
          "Environment": "Dev",
          "Project": "Tutorial"
        }
      }
    },
    "variables": {
      "uniqueStorageName": "[concat(parameters('storagePrefix'), uniqueString(resourceGroup().id))]",
      "webAppPortalName": "[concat(parameters('webAppPrefix'), uniqueString(resourceGroup().id))]"
    },
    "resources": [
      {
        "type": "Microsoft.Storage/storageAccounts",
        "apiVersion": "2021-09-01",
        "name": "[variables('uniqueStorageName')]",
        "location": "[parameters('location')]",
        "tags": "[parameters('resourceTags')]",
        "sku": {
          "name": "[parameters('storageSKU')]"
        },
        "kind": "StorageV2",
        "properties": {
          "supportsHttpsTrafficOnly": true
        }
      },
      {
        "type": "Microsoft.Storage/storageAccounts/blobServices",
        "apiVersion": "2023-05-01",
        "name": "[concat(variables('uniqueStorageName'), '/default')]",
        "sku": {
            "name": "Standard_RAGRS",
            "tier": "Standard"
        },
        "properties": {
            "containerDeleteRetentionPolicy": {
                "enabled": true,
                "days": 7
            },
            "deleteRetentionPolicy": {
                "allowPermanentDelete": false,
                "enabled": true,
                "days": 7
            }
        },
        "dependsOn": [
            "[resourceId('Microsoft.Storage/storageAccounts', variables('uniqueStorageName'))]"
        ]
      },
      {
        "type": "Microsoft.Storage/storageAccounts/blobServices/containers",
        "apiVersion": "2023-05-01",
        "name": "[concat(variables('uniqueStorageName'), '/default/', parameters('containerName'))]",
        "dependsOn": [
            "[resourceId('Microsoft.Storage/storageAccounts/blobServices', variables('uniqueStorageName'), 'default')]",
            "[resourceId('Microsoft.Storage/storageAccounts', variables('uniqueStorageName'))]"
        ],
        "properties": {
            "immutableStorageWithVersioning": {
                "enabled": false
            },
            "defaultEncryptionScope": "$account-encryption-key",
            "denyEncryptionScopeOverride": false,
            "publicAccess": "None"
        }
      },

      {
        "type": "Microsoft.Web/serverfarms",
        "apiVersion": "2021-03-01",
        "name": "[parameters('appServicePlanName')]",
        "location": "[parameters('location')]",
        "tags": "[parameters('resourceTags')]",
        "sku": {
          "name": "B1",
          "tier": "Basic",
          "size": "B1",
          "family": "B",
          "capacity": 1
        },
        "kind": "linux",
        "properties": {
          "perSiteScaling": false,
          "reserved": true,
          "targetWorkerCount": 0,
          "targetWorkerSizeId": 0
        }
      },
      {
        "type": "Microsoft.Web/sites",
        "apiVersion": "2021-03-01",
        "name": "[variables('webAppPortalName')]",
        "location": "[parameters('location')]",
        "dependsOn": [
          "[parameters('appServicePlanName')]"
        ],
        "tags": "[parameters('resourceTags')]",
        "kind": "app",
        "properties": {
          "serverFarmId": "[resourceId('Microsoft.Web/serverfarms', parameters('appServicePlanName'))]",
          "siteConfig": {
            "linuxFxVersion": "[parameters('linuxFxVersion')]"
          }
        }
      }
    ],
    "outputs": {
      "storageEndpoint": {
        "type": "object",
        "value": "[reference(variables('uniqueStorageName')).primaryEndpoints]"
      }
    }
}
TEMPLATE

  // NOTE: whilst we show an inline template here, we recommend
  // sourcing this from a file for readability/editor support
}

output "arm_example_output" {
  value = jsondecode(azurerm_resource_group_template_deployment.resources.output_content).storageEndpoint.value
}
