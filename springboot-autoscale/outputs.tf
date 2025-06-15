output "jenkins_ip" {
  value = aws_instance.jenkins.public_ip
}

output "grafana_url" {
  value = "http://${data.kubernetes_service.grafana.status.0.load_balancer.0.ingress.0.hostname}:3000"
}

output "prometheus_url" {
  value = "http://${data.kubernetes_service.prometheus.status.0.load_balancer.0.ingress.0.hostname}:9090"
}

output "app_endpoint" {
  value = "http://${kubernetes_ingress_v1.springboot_app.status.0.load_balancer.0.ingress.0.hostname}"
}

data "kubernetes_service" "grafana" {
  metadata {
    name      = "prometheus-operator-grafana"
    namespace = "monitoring"
  }
  depends_on = [helm_release.prometheus_operator]
}

data "kubernetes_service" "prometheus" {
  metadata {
    name      = "prometheus-operator-kube-p-prometheus"
    namespace = "monitoring"
  }
  depends_on = [helm_release.prometheus_operator]
}

output "artifactory_url" {
  value = "http://${aws_instance.artifactory.public_ip}:8081"
}