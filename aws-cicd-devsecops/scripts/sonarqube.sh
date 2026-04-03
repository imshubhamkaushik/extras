#!/bin/bash
set -eux

apt update -y
apt install -y docker.io

systemctl enable docker
systemctl start docker

sysctl -w vm.max_map_count=262144

docker run -d \
  --name sonarqube \
  -p 9000:9000 \
  sonarqube:lts