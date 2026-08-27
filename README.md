# Trendify Application – DevOps CI/CD Project

## 1. Project Overview

This project demonstrates an end-to-end DevOps CI/CD pipeline for deploying the **Trendify** React web application on Amazon Web Services (AWS).

The pipeline automates the complete application lifecycle:

**GitHub → GitHub Webhook → Jenkins → Docker → DockerHub → Amazon EKS → Kubernetes → LoadBalancer → Application**

The project also implements:

- Infrastructure as Code using Terraform (VPC, IAM, EC2 for Jenkins)
- Containerization using Docker
- CI/CD automation using Jenkins (declarative pipeline)
- Kubernetes deployment on Amazon EKS
- Container image management using DockerHub
- Monitoring using Prometheus
- Visualization using Grafana

---

## 2. Project Objectives

- Store application source code in GitHub
- Configure a GitHub Webhook with Jenkins for automatic build triggers on every push
- Build, tag, and test a Docker image using Jenkins
- Push the Docker image to DockerHub
- Deploy the application to Amazon EKS via `kubectl` from Jenkins
- Run the application with 2 replicas
- Expose the application using a Kubernetes LoadBalancer Service
- Verify the deployment and test the live application automatically
- Monitor Kubernetes resources using Prometheus
- Visualize metrics using Grafana dashboards
- Provision core AWS infrastructure using Terraform

---

## 3. Architecture

```text
                           Developer
                               |
                               | git push
                               v
                            GitHub
                       (Yoga-Bharath/guvi-trend-project)
                               |
                               | GitHub Webhook
                               v
                            Jenkins
                       (EC2 - 13.201.94.61:8080)
                               |
              +----------------+----------------+
              |                |                |
              v                v                v
           Checkout       Docker Build      Docker Test
                               |
                               v
                    Login to DockerHub / Push
                               |
                               v
                    yogabharath/guvi-trend-app
                               |
                               v
                       Configure EKS
                               |
                               v
                       Deploy to EKS
                               |
                               v
                        Amazon EKS
                               |
                               v
                         Kubernetes
                               |
                    +----------+----------+
                    |                     |
                    v                     v
                  Pod 1                 Pod 2
                  :3000                 :3000
                    |                     |
                    +----------+----------+
                               |
                               v
                     Kubernetes Service
                    trend-service (LoadBalancer)
                               |
                               v
                       AWS LoadBalancer
                               |
                               v
                           Internet
                               |
                               v
                       Trendify Application

                       Monitoring Architecture

                         Kubernetes
                              |
                              v
                         Prometheus
                        (monitoring ns)
                              |
                              v
                           Grafana
                              |
                              v
                    Monitoring Dashboard
```

---

## 4. Technologies Used

| Technology | Purpose |
|---|---|
| Git | Version control |
| GitHub | Source code repository |
| GitHub Webhook | Automatic Jenkins trigger |
| Jenkins | CI/CD automation |
| Docker | Application containerization |
| DockerHub | Docker image registry |
| Terraform | Infrastructure as Code (VPC, IAM, EC2/Jenkins) |
| AWS CLI | AWS management |
| Amazon EKS | Managed Kubernetes |
| Kubernetes | Container orchestration |
| Kubernetes Deployment / Service | Application deployment & networking |
| LoadBalancer | External application access |
| Nginx | Web server serving the React build |
| Prometheus | Metrics collection |
| Grafana | Monitoring dashboards |
| Linux / WSL | Development environment |

---

## 5. Project Structure

```
Trend/
│
├── Dockerfile
├── Jenkinsfile
├── README.md
├── nginx.conf
├── .gitignore
├── .dockerignore
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars
│   ├── jenkins-install.sh
│   └── ...
│
└── kubernetes-manifests/
    ├── deployment.yaml
    └── service.yaml
```

---

## 6. AWS Infrastructure (Terraform)

**Region:** `ap-south-1`

Terraform provisions the foundational AWS infrastructure and the Jenkins EC2 instance:

- `aws_vpc.main`
- `aws_subnet.public_1`, `aws_subnet.public_2`
- `aws_internet_gateway.main`
- `aws_route_table.public` + associations
- `aws_security_group.jenkins`
- `aws_iam_role.jenkins`, `aws_iam_instance_profile.jenkins`, `aws_iam_role_policy_attachment.jenkins_admin`
- `aws_instance.jenkins` (bootstrapped with `jenkins-install.sh`)

**Terraform outputs:**

```
jenkins_instance_id = "i-01fe2becb591a835a"
jenkins_public_dns  = "ec2-13-201-94-61.ap-south-1.compute.amazonaws.com"
jenkins_public_ip   = "13.201.94.61"
vpc_id              = "vpc-0989066566c5f8b7b"
```

The Amazon EKS cluster used for application deployment was provisioned separately (via `eksctl`/AWS CLI) and is managed independently of this Terraform state.

**Common commands:**

```bash
cd terraform
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
terraform output
terraform state list
terraform destroy   # when infrastructure is no longer needed
```

---

## 7. GitHub

**Repository:** `https://github.com/Yoga-Bharath/guvi-trend-project`

Contains: application source, `Dockerfile`, `Jenkinsfile`, `terraform/`, `kubernetes-manifests/`, `nginx.conf`, `.gitignore`, `.dockerignore`, `README.md`.

```bash
git status
git add .
git commit -m "Update application"
git push
```

---

## 8. GitHub Webhook

A webhook on the repository notifies Jenkins on every push:

```
Developer → git push → GitHub → Webhook → Jenkins → CI/CD Pipeline
```

Webhook payload URL: `http://13.201.94.61:8080/github-webhook/` — delivery verified successful.

Every triggered build confirms:

```
Started by GitHub push by Yoga-Bharath
```

---

## 9. Jenkins Pipeline

**Pipeline:** `Trend-CI-CD` (declarative pipeline, Jenkins on `13.201.94.61:8080`)

**Stages (all verified passing — build #6):**

1. Checkout
2. Set Image Tag
3. Build Docker Image
4. Test Docker Image
5. Login to DockerHub
6. Push to DockerHub
7. Configure EKS
8. Deploy to EKS
9. Verify Deployment
10. Test EKS Application

Image pushed as `yogabharath/guvi-trend-app:<build_number>`.

---

## 10. Docker

- Application served via **Nginx** on port **3000**
- Static files served from `/usr/share/nginx/html`

```bash
docker build -t trend-app:test .
docker run -d --name trend-app-test -p 3000:3000 trend-app:test
curl -I http://localhost:3000
```

---

## 11. DockerHub

**Repository:** `yogabharath/guvi-trend-app`

```
Jenkins → Docker Build → Docker Image → DockerHub → Amazon EKS
```

---

## 12. Amazon EKS & Kubernetes

- **Deployment:** `trend-app`, 2 replicas

```
NAME        READY   UP-TO-DATE   AVAILABLE
trend-app   2/2     2            2
```

- **Pods:** both `1/1 Running`
- **Service:** `trend-service`, type `LoadBalancer`, port `3000:31594/TCP` (default namespace)
- **Endpoints:** connected to both running pods

```bash
kubectl get deployment trend-app
kubectl get pods -o wide
kubectl get svc trend-service
kubectl get endpoints trend-service
kubectl get nodes
```

**EKS worker nodes (confirmed Ready):**

```
NAME                                          STATUS   ROLES    AGE   VERSION
ip-192-168-44-78.ap-south-1.compute.internal   Ready    <none>   23h   v1.34.9-eks-b3f9404
ip-192-168-84-114.ap-south-1.compute.internal  Ready    <none>   23h   v1.34.9-eks-b3f9404
```

---

## 13. Application URL & LoadBalancer

**Application URL:**
`http://a16c5eafc30f24352a2f5eee21c20242-b214893c3a7c6a41.elb.ap-south-1.amazonaws.com:3000`

**LoadBalancer ARN:**
`arn:aws:elasticloadbalancing:ap-south-1:822127610519:loadbalancer/net/a16c5eafc30f24352a2f5eee21c20242/b214893c3a7c6a41`

---

## 14. Monitoring – Prometheus & Grafana

Deployed in the `monitoring` namespace via the kube-prometheus-stack.

**Prometheus** — target health verified at `State: UP` for Grafana and Alertmanager ServiceMonitors.

```bash
kubectl get pods -n monitoring
kubectl get svc -n monitoring
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090
# open http://localhost:9090/targets
```

**Grafana** — "Kubernetes / Compute Resources / Cluster" dashboard shows CPU utilization, CPU requests/limits, and memory usage across `default`, `kube-system`, and `monitoring` namespaces.

```bash
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
# open http://localhost:3000
```

---

## 15. Security

The following are never committed to GitHub (enforced via `.gitignore`):

- AWS access/secret keys
- GitHub personal access tokens
- DockerHub credentials
- SSH private keys / `.pem` files
- `.env` files with secrets
- Kubernetes Secrets with sensitive data
- Terraform state files (`*.tfstate`)

DockerHub and AWS credentials are stored using **Jenkins Credentials Management**.

---

## 16. Project Evidence / Screenshots

| # | Screenshot | Proves |
|---|---|---|
| 1 | Folder structure | Local project + repo layout (Dockerfile, Jenkinsfile, terraform/, kubernetes-manifests/, .gitignore, .dockerignore) |
| 2 | Terraform folder | Terraform config files present |
| 3 | Terraform resources (`state list` + `output`) | VPC, IAM, EC2/Jenkins provisioned via IaC |
| 4 | DockerHub repo | Image pushed to `yogabharath/guvi-trend-app` |
| 5 | Jenkins job output | Full 10-stage pipeline passing, triggered by GitHub push |
| 6 | Webhook setting | GitHub → Jenkins webhook configured and delivering successfully |
| 7 | Kubernetes resources | Deployment (2/2), Pods (Running), Service (LoadBalancer), Endpoints |
| 8 | Prometheus | Targets healthy (`UP`) |
| 9 | Grafana | Cluster compute resources dashboard |
| 10 | Webpage | Live Trendify app via LoadBalancer URL on port 3000 |
| 11 | GitHub repository | Full source tree — Dockerfile, Jenkinsfile, terraform/, kubernetes-manifests/, README, .gitignore, .dockerignore, commit history |
| 12 | EKS nodes (`kubectl get nodes`) | Both EKS worker nodes `Ready`, `v1.34.9-eks-b3f9404` |

All required evidence for this submission is complete.

---

## 17. Conclusion

This project demonstrates a complete DevOps implementation for the Trendify application: a developer push to GitHub automatically triggers Jenkins via webhook, which checks out the code, builds and tests a Docker image, pushes it to DockerHub, configures access to Amazon EKS, deploys the application to Kubernetes, verifies the rollout, and tests the live endpoint. The application runs with 2 replicas behind a Kubernetes LoadBalancer Service, core AWS infrastructure is managed with Terraform, and the cluster is monitored with Prometheus and visualized in Grafana.

**Source Code → CI/CD → Containerization → Container Registry → Kubernetes (EKS) → Load Balancing → Monitoring**
