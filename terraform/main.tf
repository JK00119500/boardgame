terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "boardgame-dev"
}

data "aws_eks_cluster" "eks" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "eks" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
  load_config_file       = false
}

# ============================================================
# Security group rules for public access to the Load Balancer
# ============================================================
# We are using the *additional* security group:
#   sg-068b519bad73771fa
# Do NOT open the cluster security group (API server) to 0.0.0.0/0.

# Allow HTTP (port 80) from anywhere to the Load Balancer SG
resource "aws_security_group_rule" "lb_public_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = "sg-068b519bad73771fa"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow public HTTP access to Load Balancer"
}

# Allow HTTPS (port 443) from anywhere to the Load Balancer SG
resource "aws_security_group_rule" "lb_public_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = "sg-068b519bad73771fa"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow public HTTPS access to Load Balancer"
}
