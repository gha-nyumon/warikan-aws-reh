# bootstrap/ … すべての土台（GitHub との信頼関係・state の置き場所・GitHub Actions が借りるロール）。
# OIDC のロールを GitHub Actions 自身では作れない（鶏と卵）ので、ここだけは CloudShell から apply する。
# state はこのフォルダの terraform.tfstate（CloudShell のホーム）に置く。消さないこと。
terraform {
  required_version = "~> 1.16"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "terraform-bootstrap"
    }
  }
}
