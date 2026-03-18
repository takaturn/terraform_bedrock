terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # ローカルバックエンド (S3移行時はこのブロックを変更)
  backend "local" {}
}

provider "aws" {
  region = var.aws_region
}
