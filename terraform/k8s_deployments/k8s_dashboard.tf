# https://github.com/kubernetes/dashboard/blob/master/aio/deploy/recommended.yaml

resource "kubernetes_ingress" "kubernetes-dashboard" {
  provider = kubernetes.azure_k8s

  metadata {
    name = "kubernetes-dashboard"
    annotations = {
      "kubernetes.io/ingress.class" = "addon-http-application-routing"
      "nginx.ingress.kubernetes.io/use-regex" = "true"
      "nginx.ingress.kubernetes.io/rewrite-target" = "/$1"
    }
  }

  spec {
    backend {
      service_name = "kubernetes-dashboard"
      service_port = 80
    }

    rule {
      http {
        path {
          backend {
            service_name = "kubernetes-dashboard"
            service_port = 80
          }

          path = "/"
        }
      }
    }
  }
}