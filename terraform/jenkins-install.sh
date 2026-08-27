#!/bin/bash

set -e

dnf update -y

dnf install -y java-17-amazon-corretto git docker unzip wget

systemctl enable docker
systemctl start docker

usermod -aG docker ec2-user

wget -O /etc/yum.repos.d/jenkins.repo \
  https://pkg.jenkins.io/redhat-stable/jenkins.repo

rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2026.key

dnf install -y jenkins

systemctl enable jenkins
systemctl start jenkins

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
  -o "/tmp/awscliv2.zip"

unzip -q /tmp/awscliv2.zip -d /tmp

/tmp/aws/install

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

usermod -aG docker jenkins

systemctl restart jenkins
