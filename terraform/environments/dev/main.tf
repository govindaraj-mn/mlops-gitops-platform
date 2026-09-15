module "vpc" {
  source = "../../modules/vpc"

  name = "mlops-dev"

  vpc_cidr = "10.0.0.0/16"

  availability_zones = [
    "ap-south-1a",
    "ap-south-1b"
  ]

  private_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  public_subnet_cidrs = [
    "10.0.101.0/24",
    "10.0.102.0/24"
  ]

  tags = {
    Project = "mlops-gitops-platform"
  }
}

module "iam" {
  source = "../../modules/iam"

  name              = "mlops-dev"
  github_repository = "govindaraj-mn/mlops-gitops-platform"
}

module "eks" {
  source = "../../modules/eks"

  cluster_name    = "mlops-dev-eks"
  cluster_version = "1.33"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids



  cluster_role_arn = module.iam.eks_cluster_role_arn
  node_role_arn    = module.iam.eks_node_role_arn

  node_instance_types = ["t3.medium"]

  node_min_size     = 1
  node_max_size     = 2
  node_desired_size = 2

  endpoint_public_access = true

  public_access_cidrs = [
    "205.254.163.60/32"
  ]

  tags = {
    Project = "mlops-gitops-platform"
  }
}