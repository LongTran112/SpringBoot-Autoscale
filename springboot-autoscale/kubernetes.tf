resource "kubernetes_namespace" "app" {
  metadata {
    name = "springboot-app"
  }
}

resource "kubernetes_deployment" "springboot_app" {
  metadata {
    name      = "springboot-app"
    namespace = kubernetes_namespace.app.metadata[0].name
    labels = {
      app = "springboot"
    }
    annotations = {
      "prometheus.io/scrape" = "true"
      "prometheus.io/path"   = "/actuator/prometheus"
      "prometheus.io/port"   = "8080"
    }
  }

  spec {
    replicas = var.min_replicas

    selector {
      match_labels = {
        app = "springboot"
      }
    }

    template {
      metadata {
        labels = {
          app = "springboot"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/scheme" = "http"
        }
      }

      spec {
        container {
          image = var.app_image
          name  = "springboot-container"
          port {
            container_port = 8080
          }

          env {
            name  = "MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE"
            value = "health,metrics,prometheus"
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "springboot_app" {
  metadata {
    name      = "springboot-service"
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  spec {
    selector = {
      app = kubernetes_deployment.springboot_app.spec.0.template.0.metadata[0].labels.app
    }
    port {
      port        = 80
      target_port = 8080
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "springboot_app" {
  metadata {
    name      = "springboot-ingress"
    namespace = kubernetes_namespace.app.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }
  spec {
    rule {
      http {
        path {
          path = "/"
          backend {
            service {
              name = kubernetes_service.springboot_app.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler" "app_hpa" {
  metadata {
    name      = "springboot-hpa"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.springboot_app.metadata[0].name
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    target_cpu_utilization_percentage = 50
  }
}
