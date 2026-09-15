variable "name" {
  description = "Name prefix for IAM resources"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the GitHub Actions IAM role"
  type        = string
}

variable "github_owner_id" {
  description = "GitHub owner ID used by the immutable OIDC subject claim"
  type        = string
}

variable "github_repository_id" {
  description = "GitHub repository ID used by the immutable OIDC subject claim"
  type        = string
}