# https://codeberg.org/hjacobs/kube-ops-view/src/branch/main/deploy/rbac.yaml
resource "kubernetes_deployment" "aks-helloworld" {
  provider = kubernetes.azure_k8s

  metadata {
    name = "aks-helloworld"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "aks-helloworld"
      }
    }

    template {
      metadata {
        labels = {
          app = "aks-helloworld"
        }
      }
      spec {
        container {
          image = "mcr.microsoft.com/azuredocs/aks-helloworld:v1"
          name  = "aks-helloworld"

          port {
            container_port = "80"
            protocol = "TCP"
          }

          env {
            name = "TITLE"
            value = "Welcome to Azure Kubernetes Service (AKS)"
          }
        }
      }
    }
  }
}
resource "kubernetes_service" "aks-helloworld" {
  provider = kubernetes.azure_k8s

  metadata {
    name = "aks-helloworld"
  }
  spec {
    selector = {
      app = "aks-helloworld"
    }
    port {
      port        = 80
    }
    type = "ClusterIP"
  }
}


resource "kubernetes_ingress" "aks-helloworld" {
  provider = kubernetes.azure_k8s

  metadata {
    name = "aks-helloworld"
    annotations = {
      "kubernetes.io/ingress.class" = "addon-http-application-routing"
      "nginx.ingress.kubernetes.io/use-regex" = "true"
      "nginx.ingress.kubernetes.io/rewrite-target" = "/$1"
    }
  }

  spec {
    backend {
      service_name = "aks-helloworld"
      service_port = 80
    }

    rule {
      http {
        path {
          backend {
            service_name = "aks-helloworld"
            service_port = 80
          }

          path = "/aks-helloworld(/|$)(.*)"
        }
      }
    }
  }
}
