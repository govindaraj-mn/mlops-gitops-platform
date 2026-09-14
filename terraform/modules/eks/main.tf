module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  addons = {
  vpc-cni = {
    most_recent   = true
    before_compute = true
  }

  kube-proxy = {
    most_recent = true
  }

  coredns = {
    most_recent = true
  }
}

  authentication_mode = "API_AND_CONFIG_MAP"

  enable_cluster_creator_admin_permissions = true

  create_iam_role = false
  iam_role_arn    = var.cluster_role_arn

  endpoint_public_access = var.endpoint_public_access
  endpoint_public_access_cidrs = var.public_access_cidrs

  eks_managed_node_groups = {
    ml_nodes = {
      name = "${var.cluster_name}-ml-nodes"

      instance_types = var.node_instance_types

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      create_iam_role = false
      iam_role_arn    = var.node_role_arn

      subnet_ids = var.private_subnet_ids
    }
  }

  tags = var.tags
}