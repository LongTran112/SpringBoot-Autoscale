variable "region" {
  description = "AWS deployment region"
  default     = "us-east-1"
}

variable "min_replicas" {
  description = "Minimum number of application replicas"
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum autoscaling replicas"
  type        = number
  default     = 10
}

variable "app_image" {
  description = "Spring Boot Docker image"
  default     = "longtran112/springboot-app:latest"
}

variable "ssh_key_name" {
  description = "SSH key for instance access"
  default     = "aws-key"
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  default     = "123456" # Change in production
  sensitive   = true
}

variable "dockerhub_username" {
  description = "Docker Hub username"
  default     = "longtran112"
}

variable "dockerhub_password" {
  description = "Docker Hub password"
  sensitive   = true
}

variable "artifactory_username" {
  description = "Artifactory admin username"
  default     = "longtran112"
}

variable "artifactory_password" {
  description = "Artifactory admin password"
  default     = "123456"
  sensitive   = true
}