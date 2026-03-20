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

`apply` 後に出力される以下の値を控えておく:
- `iam_role_arn`
- `oidc_provider_arn`

### 2. GitHub Secrets の設定

GitHub リポジトリの Settings → Secrets and variables → Actions に以下を追加:

| Secret名 | 値 |
|--------|---|
| `AWS_ROLE_TO_ASSUME` | 上記の `iam_role_arn` の値 |
| `APP_ID` | GitHub App の App ID |
| `APP_PRIVATE_KEY` | GitHub App の秘密鍵 |

**GitHub App の作成方法:**
1. [GitHub Developer Settings](https://github.com/settings/apps) で新規アプリを作成
2. Permissions:
   - Pull requests: Read & write
   - Issues: Read & write
   - Contents: Read & write (PR/Issue 作成時)
3. Subscribe to events:
   - Issues, Pull requests, Issue comment, Pull request review comment
4. App ID と秘密鍵を Secrets に登録

### 3. AWS Bedrock のモデルアクセス申請

[AWS コンソール](https://console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess) で以下のモデルへのアクセスを有効化:
- Claude 4.5 Haiku（デフォルト・コスト効率重視）
- Claude 4.5 Sonnet（オプション・より高精度）
- Claude 4.6 Sonnet（オプション・最新モデル）

### 4. 動作確認

対象リポジトリの Issue または PR のコメントで:

```
@claude こんにちは！動作テストです。
```

ワークフローが自動実行され、Claude が応答します。

## DevContainer での開発

VS Code で `Dev Containers: Reopen in Container` を実行。  
ホストの `~/.aws` がマウントされ、自動で `terraform init` が実行されます。

## アーキテクチャ

```
GitHub (Issue/PR コメント)
    ↓ @claude メンション
GitHub Actions ワークフロー
    ├─ GitHub App Token 生成
    └─ OIDC Federation (短期クレデンシャル)
        ↓
AWS IAM Role (OIDC Trusted)
    ↓
AWS Bedrock (Claude 4.5 Haiku / Sonnet / 4.6 Sonnet)
    ├─ InvokeModel
    └─ InvokeModelWithResponseStream
        ↓
GitHub (コメント投稿)
```

**セキュリティ特性:**
- 長期の AWS 認証情報は不要（OIDC Federation で短期クレデンシャル発行）
- GitHub App Token で GitHub API を安全に呼び出し
- IAM ロールは main ブランチと PR ビルドに限定
- Bedrock リソースへのアクセスは明示的に許可
