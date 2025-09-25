
### InnovateMart EKS Deployment – Project Bedrock

This repository provides Infrastructure as Code (IaC) and a CI/CD pipeline to deploy the InnovateMart retail store application on Amazon Elastic Kubernetes Service (EKS).

## 🏗️ Architecture

- **EKS Cluster**: Production-grade Kubernetes cluster with managed node groups

- **VPC**: Custom networking across three Availability Zones with public and private subnets

- **Application**: Microservices-based retail store with five core services

- **Security**: Fine-grained IAM roles and read-only developer access

-**CI/CD**: Automated delivery pipeline powered by GitHub Actions

## 🚀 Getting Started
## Prerequisites

- AWS CLI configured
- Terraform >= 1.5.0
- kubectl installed

- Deploy the Infrastructure
```bash
cd terraform/eks/minimal
terraform init
terraform apply
```

- ## Deploy the Application
```bash
aws eks --region eu-north-1 update-kubeconfig --name retail-store
kubectl apply -f https://github.com/aws-containers/retail-store-sample-app/releases/latest/download/kubernetes.yaml


📂 Repository Layout
├── terraform/
│   └── eks/minimal/          # EKS infrastructure definitions
├── .github/workflows/        # CI/CD workflows
├── DEPLOYMENT_GUIDE.md       # In-depth deployment documentation
└── README.md                 # Project overview
```

## 🔐 Security Highlights

- **IAM Roles**: Implemented with least privilege for both nodes and cluster

- **Developer Access**: Restricted, read-only IAM user for safe collaboration

- **Networking**: Worker nodes deployed in private subnets

- **Encryption**: Cluster data encrypted with AWS KMS

## 🌐 Application Endpoint

- **Access the deployed application via the Load Balancer**:
http://ac6ca8f6f5b1049678042fbdb5c6603b-1143049515.us-east-1.elb.amazonaws.com/

## 🔄 CI/CD Workflows

 **Pull Requests** : Run terraform plan for preview

 **Main Branch Commits**: Run terraform apply for deployment

 **Cleanup** : Automated terraform destroy with dependency handling

## Security: AWS credentials securely managed in GitHub Secrets

- 📡 Monitoring

## Check the cluster and application status:

- kubectl get pods --all-namespaces
- kubectl get services
- kubectl logs -f deployment/ui

## 🧹 Cleanup

- Automated (Recommended):

- Use the Terraform Destroy Enhanced workflow in GitHub Actions

- Ensures safe teardown with dependency management

## Manual:

kubectl delete -f https://github.com/aws-containers/retail-store-sample-app/releases/latest/download/kubernetes.yaml
terraform destroy

## ✅ Assessment Summary
- Core Requirements Delivered

 - Terraform-based Infrastructure as Code

 - Amazon EKS cluster with VPC and IAM integration

 - Application deployment with service dependencies

 - Read-only IAM user for developers

 - CI/CD automation with GitHub Actions