resource "azurerm_kubernetes_cluster" "azure_k8s" {
    name                = "et51-k8s-example"
    location            = azurerm_resource_group.et51-rg.location
    resource_group_name = azurerm_resource_group.et51-rg.name
    dns_prefix          = "et51-k8s-example-dns"

    linux_profile {
        admin_username = "tfuser"

        ssh_key {
            key_data = tls_private_key.ssh_key.public_key_openssh
        }
    }

    default_node_pool {
        name                         = "agentpool"
        node_count                   = 3
        #vm_size                      = "Standard_DS2_v2"
        vm_size                      = "Standard_B2s"
        availability_zones           = ["1","2","3"]
        enable_auto_scaling          = false
        enable_host_encryption       = false
        enable_node_public_ip        = false
        max_pods                     = 110
        only_critical_addons_enabled = false
        orchestrator_version         = "1.19.11"
        os_disk_size_gb              = 128
        
    }

    service_principal {
        client_id     = "861b9477-7f38-4037-a681-ed1163616a28"
        client_secret = var.k8s_client_secret
    }

    network_profile {
        load_balancer_sku = "Standard"
        network_plugin = "kubenet"
    }
    
    addon_profile {
      http_application_routing {
        enabled = true
      }
      ingress_application_gateway {
        enabled       = true
        gateway_name  = "ingress-appgateway"
      } 
    }
}

data "template_file" "kube_config" {
  template   = file("${path.root}/templates/kube_config.tpl")
  depends_on = [azurerm_kubernetes_cluster.azure_k8s]

  vars = {
    kube_config  = azurerm_kubernetes_cluster.azure_k8s.kube_config_raw
  }
}

resource "local_file" "kube_config" {
  depends_on = [data.template_file.kube_config]

  content  = data.template_file.kube_config.rendered
  filename = "/home/tfuser/.kube/config"
  directory_permission = "0750"
  file_permission = "0640"
}
