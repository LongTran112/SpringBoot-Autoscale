# Spring Boot Autoscaling on AWS EKS

This project deploys a Spring Boot application on AWS EKS with autoscaling and monitoring.

## Features
- Kubernetes cluster using AWS EKS
- Horizontal Pod Autoscaling (HPA) for the Spring Boot application
- Prometheus and Grafana for monitoring
- Jenkins CI/CD server for continuous deployment

## Prerequisites
- Terraform >= 1.0.0
- AWS CLI with credentials
- kubectl
- helm

## Deployment Steps

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Review the plan:
   ```bash
   terraform plan
   ```

3. Apply the configuration:
   ```bash
   terraform apply
   ```

## Accessing Services

### Jenkins
URL: `http://<JENKINS_IP>:8080`  
Get the initial admin password by SSHing into the Jenkins instance:
```bash
ssh ec2-user@<JENKINS_IP> 'docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword'
```
## CI/CD Pipeline with DockerHub and Artifactory

### Pipeline Workflow:
1. **Checkout**: Pulls Spring Boot source code from GitHub
2. **Build**: Compiles application with Maven
3. **Docker Build**: Creates Docker image with build number tag
4. **Push to DockerHub**: Sends image to DockerHub registry
5. **Push to Artifactory**: Sends image to JFrog Artifactory
6. **Deploy to EKS**: Updates Kubernetes deployment with new image

### Setup Jenkins Credentials:
1. Access Jenkins: `http://<JENKINS_IP>:8080`
2. Add credentials:
   - `dockerhub-credentials`: Docker Hub username/password
   - `artifactory-credentials`: Artifactory admin credentials
   - `kubeconfig`: EKS kubeconfig file

### Access Artifactory:
- URL: `http://<ARTIFACTORY_IP>:8081`
- Default credentials: admin/password

### Using Artifactory as Docker Registry:
```bash
docker login <ARTIFACTORY_IP>:8082
docker push <ARTIFACTORY_IP>:8082/springboot-app:1.0

### Grafana
URL: `http://<GRAFANA_HOSTNAME>:3000`  
Username: `admin`  
Password: (as set in `variables.tf`)

### Prometheus
URL: `http://<PROMETHEUS_HOSTNAME>:9090`

### Spring Boot Application
URL: `http://<INGRESS_HOSTNAME>` (check outputs after terraform apply)

## Scalability Configuration

The solution provides two scaling mechanisms:

1. **Horizontal Pod Autoscaler (HPA)**  
   Automatically scales pods based on CPU utilization:
   ```hcl
   min_replicas = 1   # Minimum running pods
   max_replicas = 10  # Maximum pods during peak load
   ```
   Adjust these values in `variables.tf` to change scaling boundaries.

2. **Manual Replica Adjustment**  
   For baseline capacity changes:
   ```hcl
   # In variables.tf
   min_replicas = 3  # Change to 3,5,7... for higher baseline
   ```
   Then re-apply:
   ```bash
   terraform apply -var="min_replicas=3"
   ```

## Monitoring

The Spring Boot application must expose Prometheus metrics. Add these dependencies to your `pom.xml`:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

## Importing Grafana Dashboards
1. Kubernetes Cluster Monitoring: ID 3119
2. Spring Boot Statistics: ID 6756
3. JVM Micrometer: ID 4701

Deployment Steps:
Initialize Terraform:

bash
terraform init
Apply with variables:

bash
terraform apply \
  -var="dockerhub_username=" \
  -var="dockerhub_password=" \
  -var="artifactory_password="

## Notes
- The default Grafana admin password is set in `variables.tf`. Change it for production use.
- The Jenkins instance is publicly accessible. Restrict access in production.
- For production, configure persistent storage for Jenkins and Prometheus.
