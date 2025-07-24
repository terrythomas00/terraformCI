terraform {
  required_version = "1.12.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.35.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "azure-terraform-group"
    storage_account_name = "storeasttest899"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}

  subscription_id = "e39fa499-5c94-4c18-9a71-20ce68b3ac84"
}

resource "azurerm_resource_group" "dev_group" {
  name     = "azure-terraform-group"
  location = "eastus"
  tags = {
    environment = "dev"
  }
}

resource "azurerm_storage_account" "storage" {
  name                     = "storeasttest899"
  location                 = azurerm_resource_group.dev_group.location
  resource_group_name      = azurerm_resource_group.dev_group.name
  account_tier             = "Standard"
  account_replication_type = "LRS"

}
