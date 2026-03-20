output "iam_role_arn" {
  description = "GitHub Actions用IAMロールのARN (GitHub SecretのAWS_ROLE_TO_ASSUMEに設定する)"
  value       = aws_iam_role.github_actions_claude.arn
}

output "oidc_provider_arn" {
  description = "GitHub OIDC Provider ARN"
  value       = local.oidc_provider_arn
}
