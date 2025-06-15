resource "aws_instance" "jenkins" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.medium"
  subnet_id     = module.vpc.public_subnets[0]
  key_name      = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              # Install Jenkins, Docker, Maven
              sudo yum update -y
              sudo amazon-linux-extras install docker -y
              sudo service docker start
              sudo usermod -aG docker ec2-user
              sudo yum install java-11-amazon-corretto -y
              sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
              sudo yum install jenkins -y
              sudo service jenkins start
              
              # Install Maven
              sudo wget https://apache.osuosl.org/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz
              sudo tar xvf apache-maven-3.8.6-bin.tar.gz -C /opt
              sudo ln -s /opt/apache-maven-3.8.6 /opt/maven
              echo 'export M2_HOME=/opt/maven' | sudo tee /etc/profile.d/maven.sh
              echo 'export PATH=$PATH:$M2_HOME/bin' | sudo tee -a /etc/profile.d/maven.sh
              source /etc/profile.d/maven.sh
              
              # Install kubectl
              curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
              sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
              
              # Wait for Jenkins to initialize
              while [ ! -f /var/lib/jenkins/secrets/initialAdminPassword ]; do
                sleep 10
              done
              echo "Jenkins admin password: $(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)"
              EOF

  tags = {
    Name = "JenkinsController"
  }
}

# Jenkins Pipeline Definition
resource "local_file" "jenkinsfile" {
  filename = "${path.module}/Jenkinsfile"
  content  = <<-EOF
  pipeline {
    agent any
    environment {
      DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
      ARTIFACTORY_CREDENTIALS = credentials('artifactory-credentials')
      KUBECONFIG = credentials('kubeconfig')
    }
    stages {
      stage('Checkout') {
        steps {
          git branch: 'main', url: 'https://github.com/yourusername/springboot-app.git'
        }
      }
      stage('Build') {
        steps {
          sh 'mvn clean package'
        }
      }
      stage('Build Docker Image') {
        steps {
          script {
            dockerImage = docker.build("${var.dockerhub_username}/springboot-app:\${BUILD_NUMBER}")
          }
        }
      }
      stage('Push to DockerHub') {
        steps {
          script {
            docker.withRegistry('https://registry.hub.docker.com', 'DOCKERHUB_CREDENTIALS') {
              dockerImage.push()
            }
          }
        }
      }
      stage('Push to Artifactory') {
        steps {
          script {
            docker.withRegistry("http://${aws_instance.artifactory.private_ip}:8082", 'ARTIFACTORY_CREDENTIALS') {
              dockerImage.push()
            }
          }
        }
      }
      stage('Deploy to EKS') {
        steps {
          sh '''
            kubectl config use-context ${module.eks.cluster_arn}
            kubectl set image deployment/springboot-app springboot-container=${var.dockerhub_username}/springboot-app:\${BUILD_NUMBER} -n springboot-app
          '''
        }
      }
    }
  }
  EOF
}

# JFrog Artifactory Instance
resource "aws_instance" "artifactory" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.medium"
  subnet_id     = module.vpc.public_subnets[0]
  key_name      = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.artifactory_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo amazon-linux-extras install docker -y
              sudo service docker start
              sudo usermod -aG docker ec2-user
              docker run -d --name artifactory \
                -p 8081:8081 \
                -p 8082:8082 \
                -v artifactory_data:/var/opt/jfrog/artifactory \
                docker.bintray.io/jfrog/artifactory-oss:latest
              EOF

  tags = {
    Name = "ArtifactoryServer"
  }
}