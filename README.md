#### Cloud Engineering Third Semester Assignment Project
## InnovateMart’s Inaugural EKS Deployment
## NAME: ODDI, MARYAM OLAMIDE
## ALT SCHOOL ID: ALT/SOE/024/1831
### Retail Store Application
This repository contains the IAC and deployment automation for the new microservices platform- Retail Store. It uses Terraform for cloud resource provisioning and Helm for Kubernetes application deployment, orchestrated via GitHub Actions.

🔧Prerequisites

### **🔧 Required Tools**
- **AWS CLI** v2+ configured with valid credentials
- **Terraform** v1.3+ installed
- **kubectl** installed locally for cluster management
- **Node.js** v18+ for application builds and tests
- **Helm** v3+ for Kubernetes deployments
- **yq** for YAML manipulation in CI/CD

### **☁️ AWS Requirements**
- **AWS Account** with administrative permissions
- **AWS Credentials** configured via one of:
  - `aws configure` (recommended for local development)
  - Environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
  - IAM roles (for EC2/Lambda execution)
  - AWS CLI profiles

### **🔐 Required AWS Permissions**
Your AWS user/role must have permissions for:
- **VPC & Networking**: `AmazonVPCFullAccess`
- **EKS**: `AmazonEKSClusterPolicy`, EKS management permissions
- **RDS**: `AmazonRDSFullAccess`
- **DynamoDB**: `AmazonDynamoDBFullAccess`
- **ElastiCache**: `AmazonElastiCacheFullAccess`
- **Secrets Manager**: `SecretsManagerReadWrite`
- **IAM**: `IAMFullAccess` (for creating service roles)
- **EC2**: Instance and security group management

**Required GitHub Secrets:**
- `AWS_ROLE_ARN_DEV`, `AWS_ROLE_ARN_STAGING`, `AWS_ROLE_ARN_PROD` - IAM role ARNs for OIDC
- `KUBECONFIG_DEV`, `KUBECONFIG_STAGING`, `KUBECONFIG_PROD` - Kubernetes configurations
- `KUBE_NAMESPACE_DEV`, `KUBE_NAMESPACE_STAGING`, `KUBE_NAMESPACE_PROD` - K8s namespaces


## AWS Resources Created (Comprehensive)

### **🌐 Networking Infrastructure**

#### **VPC (Virtual Private Cloud)**
- **Resource**: `aws_vpc.retail_vpc`
- **Purpose**: Isolated network environment for all resources
- **Configuration**:
  - CIDR Block: `10.0.0.0/16` (65,536 IP addresses)
  - DNS Support: Enabled
  - DNS Hostnames: Enabled
- **Use Case**: Foundation for all networking components, provides network isolation

#### **Internet Gateway**
- **Resource**: `aws_internet_gateway.igw`
- **Purpose**: Provides internet connectivity to public subnets
- **Attached To**: VPC
- **Use Case**: Enables outbound internet access for NAT Gateway and public-facing resources

#### **NAT Gateway**
- **Resource**: `aws_nat_gateway.nat`
- **Purpose**: Enables private subnet resources to access internet for updates/patches
- **Configuration**:
  - Placement: Public subnet
  - Elastic IP: Attached for consistent outbound IP
- **Use Case**: EKS nodes, RDS, ElastiCache internet access without exposing them publicly

#### **Elastic IP**
- **Resource**: `aws_eip.nat`
- **Purpose**: Static IP address for NAT Gateway
- **Domain**: VPC
- **Use Case**: Consistent outbound IP for private resources, whitelisting external services

#### **Subnets**

**Public Subnets**:
- **Resource**: `aws_subnet.public`
- **CIDR**: `10.0.1.0/24` (256 IP addresses)
- **Purpose**: Internet-facing resources
- **Configuration**:
  - Auto-assign Public IP: Enabled
  - Availability Zone: Multi-AZ deployment
- **Tags**: `kubernetes.io/role/elb = 1` (ALB placement)
- **Use Case**: NAT Gateway, Application Load Balancers, bastion hosts

**Private Subnets**:
- **Resource**: `aws_subnet.private`
- **CIDR**: `10.0.2.0/24` (256 IP addresses)
- **Purpose**: Internal resources without direct internet access
- **Configuration**:
  - No public IP assignment
  - Availability Zone: Multi-AZ deployment
- **Tags**: `kubernetes.io/role/internal-elb = 1` (NLB placement)
- **Use Case**: EKS nodes, RDS instances, ElastiCache clusters

#### **Route Tables**

**Public Route Table**:
- **Resource**: `aws_route_table.public`
- **Routes**: `0.0.0.0/0` → Internet Gateway
- **Purpose**: Direct internet routing for public subnets
- **Use Case**: Internet access for public resources

**Private Route Table**:
- **Resource**: `aws_route_table.private`
- **Routes**: `0.0.0.0/0` → NAT Gateway
- **Purpose**: Internet access via NAT for private subnets
- **Use Case**: Secure internet access for private resources

#### **Route Table Associations**
- **Resources**: `aws_route_table_association.public/private`
- **Purpose**: Links subnets to appropriate route tables
- **Effect**: Determines traffic routing behavior for each subnet

---

### **🔒 Security Groups (Network Access Control)**

#### **EKS Nodes Security Group**
- **Resource**: `aws_security_group.eks_nodes_sg`
- **Purpose**: Controls network traffic to/from EKS worker nodes
- **Ingress Rules**:
  - **Self-referencing**: All ports (0-65535) TCP
    - **Purpose**: Node-to-node communication, pod networking
  - **Control Plane Communication**: Ports 1025-65535 TCP from VPC CIDR
    - **Purpose**: Kubelet and pod communication with control plane
  - **API Extensions**: Port 443 TCP from VPC CIDR
    - **Purpose**: Extension API servers communication
- **Egress Rules**: All traffic to `0.0.0.0/0`
  - **Purpose**: Internet access for container image pulls, updates
- **Use Case**: Secure EKS cluster networking, inter-pod communication

#### **RDS Security Group**
- **Resource**: `aws_security_group.rds_sg`
- **Purpose**: Database access control - restricts database access to authorized sources
- **Ingress Rules**:
  - **MySQL**: Port 3306 TCP from EKS nodes security group only
    - **Purpose**: MySQL database access from application pods
  - **PostgreSQL**: Port 5432 TCP from EKS nodes security group only
    - **Purpose**: PostgreSQL database access from application pods
- **Egress Rules**: All traffic to `0.0.0.0/0`
  - **Purpose**: Database maintenance, updates, replication
- **Use Case**: Restrict database access to only authorized EKS applications

#### **ElastiCache Security Group**
- **Resource**: `aws_security_group.elasticache_sg`
- **Purpose**: Redis cache access control
- **Ingress Rules**:
  - **Redis**: Port 6379 TCP from EKS nodes security group only
    - **Purpose**: Redis access from application pods for caching/sessions
- **Egress Rules**: All traffic to `0.0.0.0/0`
  - **Purpose**: Maintenance and monitoring
- **Use Case**: Secure Redis access from applications only, prevent unauthorized access

---

### **👤 IAM Roles & Policies (Comprehensive)**

#### **EKS Cluster Service Role**
- **Resource**: `aws_iam_role.eks_cluster_role`
- **Purpose**: Allows EKS service to manage cluster resources on your behalf
- **Trust Policy**: 
  ```json
  {
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "eks.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }
  ```
- **Attached AWS Managed Policies**:
  - `AmazonEKSClusterPolicy` - Core EKS cluster management permissions
- **Specific Permissions Include**:
  - Create/manage ENIs for cluster networking
  - Manage cluster lifecycle (create, update, delete)
  - CloudWatch logging integration
  - VPC resource management for cluster
  - Security group management for cluster
- **Use Case**: EKS control plane operations, cluster management

#### **EKS Node Group Service Role**
- **Resource**: `aws_iam_role.eks_node_role`
- **Purpose**: Allows EC2 instances to join EKS cluster as worker nodes
- **Trust Policy**:
  ```json
  {
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ec2.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }
  ```
- **Attached AWS Managed Policies**:
  - `AmazonEKSWorkerNodePolicy` - Node registration and management
  - `AmazonEKS_CNI_Policy` - VPC CNI plugin for pod networking
  - `AmazonEC2ContainerRegistryReadOnly` - Pull container images from ECR
- **Specific Permissions Include**:
  - EC2 instance management and metadata access
  - ENI creation/attachment for pod networking
  - ECR image pulling and authentication
  - CloudWatch metrics and logs publishing
  - Auto Scaling group management
- **Use Case**: Worker node operations, pod networking, container runtime

### **🚀 Application Deployment (Detailed)**

#### **Kubernetes Namespace**
- **Management**: Helm-managed namespace creation
- **Purpose**: Logical isolation and organization of application resources
- **Configuration**: Environment-specific naming (dev, staging, prod)
- **Features**:
  - **Resource Quotas**: Can be applied for resource management
  - **Network Policies**: Can be applied for network segmentation
  - **RBAC**: Role-based access control boundaries
- **Use Case**: Multi-tenancy, resource organization, security boundaries

#### **Microservices Architecture**
