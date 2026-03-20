# GitHub Actions OIDC Provider
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# 現在のAWSセッション情報を取得
data "aws_caller_identity" "current" {}

# 既存のOIDC Providerが無い場合は作成
resource "aws_iam_openid_connect_provider" "github" {
  count = length(data.aws_iam_openid_connect_provider.github.arn) > 0 ? 0 : 1

  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = {
    Name    = "github-actions-oidc"
    ManagedBy = "terraform"
  }
}

# OIDC Provider ARN (既存 or 新規作成)
locals {
  oidc_provider_arn = length(aws_iam_openid_connect_provider.github) > 0 ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github.arn
}

# GitHub Actions用 IAMロール
resource "aws_iam_role" "github_actions_claude" {
  name = var.iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # mainブランチと全PRのみ許可
            "token.actions.githubusercontent.com:sub" = [
              "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main",
              "repo:${var.github_org}/${var.github_repo}:pull_request",
              "repo:${var.github_org}/${var.github_repo}:environment:*",
            ]
          }
        }
      }
    ]
  })

  tags = {
    Name      = var.iam_role_name
    ManagedBy = "terraform"
  }
}

# Bedrock InvokeModel ポリシー
resource "aws_iam_role_policy" "bedrock_invoke" {
  name = "bedrock-invoke-claude"
  role = aws_iam_role.github_actions_claude.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "BedrockInvokeModel"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream",
        ]
        Resource = [
          # Claude 4.5 Haiku (動作確認向け・コスパ重視)
          "arn:aws:bedrock:${var.aws_region}::foundation-model/anthropic.claude-haiku-4-5-20251001-v1:0",
          "arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:inference-profile/us.anthropic.claude-haiku-4-5-20251001-v1:0",
          # Claude 4.6 Sonnet (将来の指定切り替え用に残す)
          "arn:aws:bedrock:${var.aws_region}::foundation-model/anthropic.claude-sonnet-4-6",
          "arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:inference-profile/us.anthropic.claude-sonnet-4-6",
        ]
      },
      {
        Sid    = "BedrockListModels"
        Effect = "Allow"
        Action = [
          "bedrock:ListFoundationModels",
          "bedrock:GetFoundationModel",
        ]
        Resource = "*"
      }
    ]
  })
}
