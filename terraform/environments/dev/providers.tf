provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "mlops-gitops-platform"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}