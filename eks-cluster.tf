variable "cluster-name" {
  description = "The name of the EKS cluster"
  type        = string
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster-name
  kubernetes_version = "1.33"

  addons = {
    coredns                = {
        before_compute = true
    }
     
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy             = {}
    vpc-cni                = {
      before_compute = true
    }
    aws-ebs-csi-driver     = {
        most_recent = true
        service_account_role_arn = "arn:aws:iam::314146320372:role/AmazonEKS_EBS_CSI_DriverRole"
    }
  }

  iam_role_additional_policies = {
    AmazonEBSSCIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"

  }



  endpoint_public_access = true
  enable_irsa = true
#   enable_cluster_creator_admin_permissions = true


  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets


  eks_managed_node_groups = {
    InnovateMart-nodegroup = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 6
      desired_size = 5
    }
  }

  tags = {
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
    Name = var.cluster-name
    Environment = "dev"
    Terraform   = "production"
  }

access_entries = {
    admin_user = {
        kubernetes_groups = []
      principal_arn = "arn:aws:iam::314146320372:user/Terraform-user"

      policy_associations = {
        admin_policy = {
          policy_arn =  "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type       = "cluster"
          }
        }
      }
    }
    dev-innocent = {
        kubernetes_groups = []
      principal_arn = "arn:aws:iam::314146320372:user/dev-altsch"

      policy_associations = {
        view = {
          policy_arn =  "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminViewPolicy"
          access_scope = {
            type       = "cluster"
          }
        }
      }

      }
    }
}





