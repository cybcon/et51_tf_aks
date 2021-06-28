terraform {
  backend "azurerm" {
  }
}

provider "azurerm" {
  environment     = "public"
  tenant_id       = var.azure_tenant_id
  subscription_id = var.azure_subscription_id
  features {}
}
data "azurerm_client_config" "current" {}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_resource_group" "et51-rg" {
  name     = "et51-rg"
  location = var.region
}
