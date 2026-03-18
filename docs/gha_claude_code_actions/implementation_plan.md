# 実装計画: Claude Code Action on AWS Bedrock

## 概要

**目標**: AWS Bedrock 上の Claude モデルを使い、GitHub Actions で `claude-code-action` を動作させる。

**アーキテクチャの要点**:
- GitHub Actions から AWS Bedrock に安全にアクセスするため **OIDC (OpenID Connect)** を使用（長期クレデンシャル不要）
- **Terraform** で AWS リソース（IAM OIDC Provider / Role / Policy）を管理
- **DevContainer** でローカル開発・動作確認環境を提供

---

## アーキテクチャ図

```
GitHub Actions Workflow
      │  @claude mention / PR event
      ▼
claude-code-action (anthropics/claude-code-action)
      │  OIDC Token → AssumeRole
      ▼
AWS IAM Role (FederatedPrincipal: GitHub OIDC)
      │  InvokeModel
      ▼
AWS Bedrock (Claude 3.5 Sonnet / Claude 3 Opus)
```

---

## ユーザー確認事項

> [!IMPORTANT]
> 以下の情報を事前に確認・準備してください：
> - **AWS アカウント ID** (Terraform変数として使用)
> - **AWS リージョン** (Bedrock 利用可能リージョン推奨: `us-east-1` または `ap-northeast-1`)
> - **GitHub Org/Repo 名** (OIDC の Subject 制限に使用)
> - **Bedrock のモデルアクセス申請** が完了しているか（Claude 3.5 Sonnet など）

> [!WARNING]
> `ap-northeast-1`（東京）では Bedrock で利用できる Claude モデルが限られます。Cross-Region Inference を使うか `us-east-1` などの利用を検討してください。

---

## 提案する変更内容

### Terraform (AWS インフラ)

```
terraform_bedrock/
├── terraform/
│   ├── main.tf          # プロバイダー・バックエンド
│   ├── iam.tf           # OIDC Provider + IAM Role + Policy
│   ├── variables.tf     # 変数定義
│   └── outputs.tf       # 出力 (Role ARN など)
```

#### [NEW] `terraform/main.tf`
- AWS プロバイダー設定
- Terraform バックエンド設定 (local or S3)

#### [NEW] `terraform/iam.tf`
- **GitHub OIDC Provider** (`token.actions.githubusercontent.com`)
- **IAM Role** (GitHub ActionsがAssumeRoleできるFederated Role)
- **IAM Policy** (`bedrock:InvokeModel`, `bedrock:InvokeModelWithResponseStream`)

#### [NEW] `terraform/variables.tf`
- `aws_account_id`, `aws_region`, `github_org`, `github_repo` など

#### [NEW] `terraform/outputs.tf`
- IAM Role ARN の出力

---

### GitHub Actions ワークフロー

```
.github/
└── workflows/
    └── claude-code-action.yml   # claude-code-action のワークフロー
```

#### [NEW] `.github/workflows/claude-code-action.yml`
```yaml
name: Claude Code Action
on:
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]

permissions:
  id-token: write        # OIDC に必要
  contents: write
  pull-requests: write
  issues: write

jobs:
  claude:
    if: contains(github.event.comment.body, '@claude')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: AWS認証 (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-1
      - uses: anthropics/claude-code-action@beta
        with:
          claude_model: "us.anthropic.claude-3-5-sonnet-20241022-v2:0"
          use_bedrock: "true"
          github_token: ${{ secrets.GITHUB_TOKEN }}
```

---

---

## 検証計画

### 自動確認
```bash
# ローカル環境内でTerraformの構文確認
cd terraform && terraform init && terraform validate && terraform plan

# AWS認証確認
aws sts get-caller-identity
aws bedrock list-foundation-models --region us-east-1
```

### 手動確認
1. Terraform apply でAWSリソース作成確認
2. GitHub リポジトリの Issue/PRコメントで `@claude` メンションを送信
3. GitHub Actionsワークフローが起動し、Claude から返答が来ることを確認
