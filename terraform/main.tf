terraform {
  backend "azurerm" {
  }
}

provider "azurerm" {
  environment     = "public"
  tenant_id       = "6c3b9954-2075-41bc-af53-36e3975951e6"
  subscription_id = "337b8d5c-b363-45ac-833c-13e19225646f"
  client_id       = "15c10793-cbca-4ec9-87ea-017d091ba70c"
  client_secret   = var.client_secret
  features {}
}
data "azurerm_client_config" "current" {}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_resource_group" "et51-rg" {
  name     = "et51-rg"
  location = "westeurope"
}
