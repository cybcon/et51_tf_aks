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
            #value = "Welcome to Azure Kubernetes Service (AKS)"
            value = "Willkommen beim Entwicklertag 51"
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
      # https://kubernetes.github.io/ingress-nginx/examples/rewrite/
      "kubernetes.io/ingress.class" = "addon-http-application-routing"
      #"nginx.ingress.kubernetes.io/ssl-redirect" = "false"
      #"nginx.ingress.kubernetes.io/use-regex" = "true"
      #"nginx.ingress.kubernetes.io/rewrite-target" = "/$1"
      #"nginx.ingress.kubernetes.io/app-root" = "/"
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
          path = "/"
          backend {
            service_name = "aks-helloworld"
            service_port = 80
          }
        }
      }
    }
  }
}

output "aks-helloworld_url" {
  value = "https://${kubernetes_ingress.aks-helloworld.status.0.load_balancer.0.ingress.0.ip}/aks-helloworld/"
}

