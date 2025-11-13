module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Enable public endpoint so you can access from your local machine
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access_cidrs     = ["223.185.36.255/32"]

  eks_managed_node_groups = {
    default = {
      desired_size = 2
      max_size     = 3
      min_size     = 1

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      iam_role_arn   = aws_iam_role.eks_node_role.arn
    }
  }
 access_entries = {
    admin = {
      principal_arn     = "arn:aws:iam::599801266123:root"  
      kubernetes_groups = ["system:masters"]
    }
  }

  tags = {
    Environment = "dev"
  }
}