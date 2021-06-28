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
        name            = "agentpool"
        node_count      = 3
        vm_size         = "Standard_D2_v2"
    }

    service_principal {
        client_id     = "861b9477-7f38-4037-a681-ed1163616a28"
        client_secret = var.k8s_client_secret
    }

    network_profile {
        load_balancer_sku = "Standard"
        network_plugin = "kubenet"
    }
}