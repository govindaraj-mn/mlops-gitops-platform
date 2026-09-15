provider "aws" {
  region  = var.aws_region
  profile = "mlops-dev"

  default_tags {
    tags = {
      Project     = "mlops-gitops-platform"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}