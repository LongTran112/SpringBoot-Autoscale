resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "prometheus_operator" {
  name       = "prometheus-operator"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "46.8.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = "false"
  }

  set {
    name  = "grafana.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  depends_on = [module.eks]
}

resource "kubernetes_manifest" "springboot_service_monitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "springboot-monitor"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
    }
    spec = {
      selector = {
        matchLabels = {
          app = "springboot"
        }
      }
      namespaceSelector = {
        matchNames = [kubernetes_namespace.app.metadata[0].name]
      }
      endpoints = [{
        port     = "http"
        interval = "15s"
        path     = "/actuator/prometheus"
      }]
    }
  }
  depends_on = [helm_release.prometheus_operator]
}
