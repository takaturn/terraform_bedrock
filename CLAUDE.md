# CLAUDE.md

このファイルは、本リポジトリでコードを操作する際の Claude Code (claude.ai/code) への指針を提供します。

## プロジェクト概要

これは **Terraform ベースのインフラストラクチャプロジェクト** で、AWS Bedrock を使用して GitHub Actions 経由で Claude Code を運用するための AWS リソースをプロビジョニングします。GitHub Actions と AWS 間の安全な認証情報管理に OIDC フェデレーションを使用しています。

### 主要なアーキテクチャ
- **GitHub Actions ワークフロー** (`claude-code-action.yml`): Issue、PR、コメント内の `@claude` メンションをリッスンします
- **OIDC フェデレーション**: GitHub Actions が OpenID Connect を使用して AWS IAM ロールを引き受けます（長期認証情報は保存されません）
- **AWS Bedrock 統合**: AWS Bedrock API 経由で Claude モデル（Haiku、Sonnet）を使用します
- **GitHub App**: コメントとコンテンツの作成・更新に認証されたアクセスを提供します

## Terraform ワークフロー＆コマンド

すべての Terraform 操作は `terraform/` ディレクトリで実行します。

### 必須コマンド
```bash
cd terraform

# 状態を初期化し、プロバイダーをダウンロード（クローン後に一度実行）
terraform init

# 変更内容をプレビュー
terraform plan

# インフラストラクチャの変更を適用
terraform apply

# インフラストラクチャを破棄（注意して使用）
terraform destroy

# すべての .tf ファイルをフォーマット（コミット前に実行）
terraform fmt

# 構文を検証
terraform validate
```

セットアップ手順の詳細は README.md を参照してください。

## プロジェクト構造

詳細は README.md を参照してください。重要なファイル：
- `terraform/main.tf`: プロバイダー設定（Terraform ≥1.5.0、AWS ~5.0）
- `terraform/iam.tf`: OIDC プロバイダー + IAM ロール + Bedrock ポリシー
- `terraform/variables.tf`: 入力変数（デフォルト値付き）
- `terraform/outputs.tf`: 出力：iam_role_arn、oidc_provider_arn
- `.github/workflows/claude-code-action.yml`: メイン GitHub Actions ワークフロー（テストなしで変更しないこと）

## 重要な実装詳細

### GitHub Actions ワークフロー (`claude-code-action.yml`)
- **トリガーイベント**: `@claude` を含む Issue コメント、PR レビューコメント、新規 Issue
- **GitHub App トークン生成**: `actions/create-github-app-token@v2` で安全な GitHub API アクセスを実現
- **OIDC 引き受け**: `aws-actions/configure-aws-credentials@v4` で IAM ロールを引き受けます
- **デフォルトモデル**: Claude 4.5 Haiku（コスト効率的、`claude_args` で上書き可能）
- **最大ターン数**: デフォルト 10（ワークフローで設定可能）

**注意**: 十分なテストなしでワークフローを変更しないでください。これは GitHub ↔ AWS の重要な統合を制御しています。

### IAM セキュリティモデル (`iam.tf`)
- **OIDC プロバイダー**: GitHub の公式トークンエンドポイント (`https://token.actions.githubusercontent.com`) を使用
- **信頼条件**: 以下からのみ引き受けを許可：
  - `main` ブランチ
  - すべてのプルリクエスト（任意のブランチ）
  - すべての環境（将来の拡張に柔軟に対応）
- **Bedrock パーミッション**: Haiku、Sonnet（4.5）、Sonnet（4.6）モデルの明示的なリソース ARN
- **サムプリント**: GitHub の証明書チェーン用に 2 つのサムプリントをピン留めしています（GitHub が証明書を変更した場合は更新）

### Terraform 状態管理
- **現在**: ローカルバックエンド（`backend "local"`）
- **移行パス**: S3 バックエンドに移行するには、`main.tf` の `backend "local"` ブロックを変更し、`terraform init` を新しいバックエンド設定で実行します
- **状態ファイル**: `terraform.tfstate` は `.gitignore` に含まれています（コミットしないこと）

## 回答言語とドキュメント

`AGENTS.md` に準じて：
- 特に指示がない限り **日本語** で回答してください
- 実装計画、チュートリアル、タスクリストは **日本語** で作成してください
- シンプルなタスクでコード変更が伴わない場合はドキュメントファイルを省略してください
- 必要に応じて `docs/<topic_folder>/` にドキュメントを保存してください（例：`docs/oidc_security/`）

## テストと検証

### ローカル Terraform テスト
```bash
cd terraform
terraform validate           # 構文チェック
terraform fmt --check       # フォーマット検証（--check なしで自動修正）
terraform plan | tee plan.txt  # apply 前に計画を確認
```

その他のテスト方法は README.md を参照してください。

## よくある開発パターン

### 新しい IAM パーミッションを追加
1. ポリシーを特定します（例：新しい Bedrock モデル）
2. 関連するポリシーリソースの下で `terraform/iam.tf` を編集します
3. リソース ARN をリストに追加します
4. `terraform plan` で検証します
5. `terraform apply` を実行します

### モデル ARN の更新
`iam.tf` のモデル ARN は以下のパターンに従います：
```
arn:aws:bedrock:${var.aws_region}::foundation-model/<model-id>
arn:aws:bedrock:${var.aws_region}:${account_id}:inference-profile/*.<model-id>
```
新しいモデルを追加する際は、両方のパターンを必ず含めてください。

### GitHub Secrets の設定
GitHub Secrets の設定方法は README.md を参照してください。これらをリポジトリにコミット **しないでください**。

## トラブルシューティング

### Terraform Apply が OIDC エラーで失敗する
- `iam.tf` のサムプリントが GitHub の現在の証明書と一致していることを確認します
- AWS コンソール確認：IAM → Identity Providers → GitHub Actions

### ワークフローがトリガーされない
- コメント本文に `@claude` メンションが含まれていることを確認します（完全一致、大文字と小文字を区別）
- GitHub Secrets が正しく設定されていることを確認します
- `AWS_ROLE_TO_ASSUME` の IAM ロール ARN が Terraform 出力と一致していることを確認します

### Bedrock InvokeModel がアクセス拒否される
- AWS コンソールでモデルアクセスが有効になっていることを確認します：Bedrock → Model access
- IAM ポリシーに `iam.tf` の特定モデル ARN が含まれていることを確認します
- AWS リージョンがワークフロー設定（`ap-northeast-1`）と一致していることを確認します

## 外部リソース

- [AWS Bedrock ドキュメント](https://docs.aws.amazon.com/bedrock/)
- [Terraform AWS プロバイダー ドキュメント](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions OIDC](https://docs.aws.amazon.com/IAM/latest/UserGuide/access-analyzer-access-tokens.html)
- [GitHub App パーミッション](https://docs.github.com/en/apps/building-oauth-apps/understanding-scopes-for-oauth-apps)
