# terraform_bedrock

AWS Bedrock 上の Claude Code を使って GitHub Actions (`claude-code-action`) を動作させるためのリポジトリです。

## 構成

```
.
├── .devcontainer/           # VS Code DevContainer
│   ├── devcontainer.json
│   └── Dockerfile
├── .github/
│   └── workflows/
│       └── claude-code-action.yml  # Claude Code GHAワークフロー
└── terraform/               # AWS インフラ (IaC)
    ├── main.tf              # プロバイダー設定
    ├── iam.tf               # OIDC Provider + IAM Role
    ├── variables.tf         # 変数定義
    └── outputs.tf           # 出力値
```

## セットアップ手順

### 1. AWS インフラの作成 (Terraform)

```bash
cd terraform

# 初期化
terraform init

# 確認
terraform plan

# 適用
terraform apply
```

`apply` 後に出力される `iam_role_arn` を控えておく。

### 2. GitHub Secrets の設定

GitHub リポジトリの Settings → Secrets and variables → Actions に以下を追加:

| Secret名 | 値 |
|--------|---|
| `AWS_ROLE_ARN` | 上記の `iam_role_arn` の値 |

### 3. AWS Bedrock のモデルアクセス申請

[AWS コンソール](https://console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess) で `Claude 3.5 Sonnet v2` のアクセスを有効化。

### 4. 動作確認

対象リポジトリの Issue または PR のコメントで:

```
@claude こんにちは！動作テストです。
```

## DevContainer での開発

VS Code で `Dev Containers: Reopen in Container` を実行。  
ホストの `~/.aws` がマウントされ、自動で `terraform init` が実行されます。

## アーキテクチャ

```
GitHub (Issue/PR コメント)
    ↓ @claude メンション
GitHub Actions ワークフロー
    ↓ OIDC (短期クレデンシャル)
AWS IAM Role
    ↓ InvokeModel
AWS Bedrock (Claude 3.5 Sonnet)
    ↓ 返答
GitHub (コメント投稿)
```
