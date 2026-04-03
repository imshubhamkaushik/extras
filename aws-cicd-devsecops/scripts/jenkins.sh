#!/bin/bash
set -eux

# -------------------------------
# System Setup
# -------------------------------
apt update -y
apt install -y curl unzip git docker.io openjdk-21-jdk

systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

# -------------------------------
# Install Jenkins
# -------------------------------
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io.key | tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian binary/" \
> /etc/apt/sources.list.d/jenkins.list

apt update -y
apt install -y jenkins

# -------------------------------
# Install Jenkins Plugins
# -------------------------------
mkdir -p /var/lib/jenkins/plugins

cat <<EOF > /tmp/plugins.txt
configuration-as-code
git
workflow-aggregator
docker-workflow
credentials-binding
aws-credentials
pipeline-stage-view
blueocean
sonar
EOF

jenkins-plugin-cli --plugin-file /tmp/plugins.txt

# -------------------------------
# Install DevOps Tools
# -------------------------------

# AWS CLI
apt install -y awscli

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Trivy
wget https://github.com/aquasecurity/trivy/releases/latest/download/trivy_0.50.0_Linux-64bit.deb
dpkg -i trivy_0.50.0_Linux-64bit.deb

# -------------------------------
# JCasC Setup
# -------------------------------
mkdir -p /var/lib/jenkins/casc_configs

cat <<EOF > /var/lib/jenkins/casc_configs/jcasc.yaml
${file("${path.module}/templates/jcasc.yaml")}
EOF

chown -R jenkins:jenkins /var/lib/jenkins

# -------------------------------
# Environment Variables
# -------------------------------
cat <<EOF >> /etc/default/jenkins
CASC_JENKINS_CONFIG=/var/lib/jenkins/casc_configs/jcasc.yaml

JENKINS_ADMIN_USER=admin
JENKINS_ADMIN_PASSWORD=admin123

JENKINS_URL=${jenkins_url}
SONAR_HOST=${sonar_host}

GITHUB_TOKEN=${github_token}
SONAR_TOKEN=${sonar_token}
GIT_REPO_URL=${repo_url}
EOF

# -------------------------------
# Start Jenkins
# -------------------------------
systemctl enable jenkins
systemctl restart jenkins