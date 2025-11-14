module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # EKS API endpoint access
  cluster_endpoint_public_access       = true
  cluster_endpoint_private_access      = true
  # For demo: allow from anywhere. In real use, restrict to your IP / VPN.
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  # Managed node group
  eks_managed_node_groups = {
    default = {
      desired_size = 2
      max_size     = 3
      min_size     = 1

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      # Let module create the IAM role for node group automatically
    }
  }

  # Extra rule on node security group – allow inbound app traffic on 8080
  node_security_group_additional_rules = {
    ingress_http_8080 = {
      description      = "Allow inbound HTTP traffic on 8080 from internet"
      protocol         = "tcp"
      from_port        = 8080
      to_port          = 8080
      type             = "ingress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  # EKS Access Entries – give Jenkins IAM user cluster-admin access
  access_entries = {
    jenkins_admin = {
      principal_arn = "arn:aws:iam::599801266123:user/boardgame-terraform"

      access_policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  tags = {
    Environment = "dev"
  }
}
