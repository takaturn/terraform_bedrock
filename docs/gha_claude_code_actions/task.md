# タスクリスト: Claude Code Action on AWS Bedrock

## フェーズ1: 計画・設計
- [x] 技術要件の調査（Bedrock, GHA, OIDC, Terraform）
- [x] 実装計画書の作成
- [x] ユーザーによる計画承認

## フェーズ2: AWS インフラ (Terraform)
- [x] Terraformプロジェクト構成の作成
  - [x] `main.tf` (プロバイダー、バックエンド設定)
  - [x] `iam.tf` (OIDC Provider, IAM Role, IAM Policy)
  - [x] `variables.tf` (変数定義)
  - [x] `outputs.tf` (出力値)
- [x] Bedrock Model Accessの有効化確認

## フェーズ3: GitHub Actions ワークフロー
- [x] `.github/workflows/claude-code-action.yml` の作成
  - [x] OIDCを使ったAWS認証ステップ
  - [x] claude-code-action の呼び出し設定
  - [x] Bedrock モデルID・リージョンの設定

## フェーズ4: DevContainer 設定
- [x] `.devcontainer/devcontainer.json` の作成
- [x] `.devcontainer/Dockerfile` の作成
  - [x] AWS CLI, Terraform, Node.js, GitHub CLI インストール
- [ ] DevContainer内での動作確認手順の整備

## フェーズ5: 検証
- [/] Terraform plan/apply の実行確認 (ローカル環境にて進行中)
- [ ] GHA ワークフローのテスト実行
- [ ] DevContainer からの動作確認
