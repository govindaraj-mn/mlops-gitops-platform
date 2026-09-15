variable "name" {
  description = "Name prefix for IAM resources"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the GitHub Actions IAM role"
  type        = string
}
