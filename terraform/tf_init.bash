#!/bin/bash
##############################################################################
# Initialzie Terraform and use state file in Azure Storage Account
# Author: Michael Oberdorf
# Date: 2021-06-28
##############################################################################

#-----------------------------------------------------------------------------
# V A R I A B L E S
#-----------------------------------------------------------------------------
# Terraform configuration directory
TF_BASEDIR='/home/tfuser/et51_tf_aks/terraform'
# Terraform plugin directory
TF_PLUGIN_DIR="${TF_BASEDIR}/.terraform"

# terraform.tfvars with secrets
TFVARS="${TF_BASEDIR}/terraform.tfvars"
if [ -f "${TFVARS}" ]; then
  source ${TFVARS}
fi

# Terraform statefile parameters for Azure storage account backend
azurerm_backend_resource_group_name='services-rg'
azurerm_backend_storage_account_name='et51storage'
azurerm_backend_blob_storage_container_name='terraform-state-files'
azurerm_backend_state_file_name='aks.tfstate'
#FROM TFVARS: azurerm_backend_storage_account_access_key
if [ -z "${azurerm_backend_storage_account_access_key}" ]; then
  echo "ERROR: please maintain file ${TFVARS} and add storage account key in variable: azurerm_backend_storage_account_access_key!" >&2
  exit 1
fi


##############################################################################
# M A I N
##############################################################################

# remove plugin dir if exist
if [ -d "${TF_PLUGIN_DIR}" ]; then
  rm -rf ${TF_PLUGIN_DIR}
fi

# init terraform with azure storage account backend for state file
terraform init \
  -backend=true \
  -backend-config="resource_group_name=${azurerm_backend_resource_group_name}" \
  -backend-config="storage_account_name=${azurerm_backend_storage_account_name}" \
  -backend-config="container_name=${azurerm_backend_blob_storage_container_name}" \
  -backend-config="key=${azurerm_backend_state_file_name}" \
  -backend-config="access_key=${azurerm_backend_storage_account_access_key}"
