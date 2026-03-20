variable "aws_region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "github_org" {
  description = "GitHubオーガニゼーション名"
  type        = string
  default     = "takaturn"
}

variable "github_repo" {
  description = "GitHubリポジトリ名"
  type        = string
  default     = "terraform_bedrock"
}

variable "iam_role_name" {
  description = "GitHub Actions用IAMロール名"
  type        = string
  default     = "github-actions-claude-code-bedrock"
}
