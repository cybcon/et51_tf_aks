# https://codeberg.org/hjacobs/kube-ops-view/src/branch/main/deploy/rbac.yaml
resource "kubernetes_service_account" "kube-ops-view" {
  provider = kubernetes.azure_k8s
  
  metadata {
    name = "kube-ops-view"
  }
}
resource "kubernetes_cluster_role" "kube-ops-view" {
  provider = kubernetes.azure_k8s
  
  metadata {
    name = "kube-ops-view"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes", "pods"]
    verbs      = ["list"]
  }
  rule {
    api_groups = ["metrics.k8s.io"]
    resources  = ["nodes", "pods"]
    verbs      = ["get","list"]
  }
}
resource "kubernetes_cluster_role_binding" "kube-ops-view" {
  provider = kubernetes.azure_k8s
  
  metadata {
    name = "kube-ops-view"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "kube-ops-view"
  }
  subject {
    kind      = "ServiceAccount"
    #name      = kubernetes_service_account.kube-ops-view.metadata[0]
    name      = "kube-ops-view"
    namespace = "default"
  }
}


# https://codeberg.org/hjacobs/kube-ops-view/src/branch/main/deploy/service.yaml
resource "kubernetes_service" "kube-ops-view" {
  provider = kubernetes.azure_k8s

  metadata {
    name = "kube-ops-view"
    labels = {
      application = "kube-ops-view",
      component = "frontend"
    }
  }
  spec {
    selector = {
      app = "kube-ops-view"
      component = "frontend"
    }
    session_affinity = "ClientIP"
    port {
      port        = 80
      target_port = 8080
    }
    #type = "LoadBalancer"
    type = "ClusterIP"
  }
}


# https://codeberg.org/hjacobs/kube-ops-view/src/branch/main/deploy/deployment.yaml
resource "kubernetes_deployment" "kube-ops-view" {
  provider = kubernetes.azure_k8s

  metadata {
    name = "kube-ops-view"
    labels = {
      application = "kube-ops-view",
      component = "frontend"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        application = "kube-ops-view"
        component = "frontend"
      }
    }

    template {
      metadata {
        labels = {
          application = "kube-ops-view",
          component = "frontend"
        }
      }
      spec {
        #service_account_name = kubernetes_service_account.kube-ops-view.metadata[0]
        service_account_name      = "kube-ops-view"

        container {
          image = "hjacobs/kube-ops-view:20.4.0"
          name  = "service"

          port {
            container_port = "8080"
            protocol = "TCP"
          } 

          resources {
            limits = {
              cpu    = "200m"
              memory = "100Mi"
            }
            requests = {
              cpu    = "50m"
              memory = "50Mi"
            }
          }

          security_context {
            read_only_root_filesystem = true
            run_as_non_root = true
            run_as_user = "1000"
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8080
            }

            initial_delay_seconds = 5
            timeout_seconds        = 1
          }
          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }

            initial_delay_seconds = 30
            period_seconds        = 30
            timeout_seconds       = 10
            failure_threshold     = 5
          }
        }
      }
    }
  }
}

# https://docs.microsoft.com/de-de/azure/aks/http-application-routing
resource "kubernetes_ingress" "kube-ops-view" {
  provider = kubernetes.azure_k8s
  
  metadata {
    name = "kube-ops-view"
    annotations = {
      "kubernetes.io/ingress.class" = "addon-http-application-routing"
    }
  }

  spec {
    backend {
      service_name = "kube-ops-view"
      service_port = 80
    }

    rule {
      http {
        path {
          backend {
            service_name = "kube-ops-view"
            service_port = 80
          }

          path = "/kube-ops-view/*"
        }
      }
    }
  }
}
