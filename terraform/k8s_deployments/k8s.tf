provider "kubernetes" {
    host                   = azurerm_kubernetes_cluster.azure_k8s.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.azure_k8s.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.azure_k8s.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.azure_k8s.kube_config.0.cluster_ca_certificate)
    alias                  = "azure_k8s"

    # config_path    = "~/.kube/config"
    config_context = azurerm_kubernetes_cluster.azure_k8s.name
}