# infra/ … アプリを載せるもの（Lambda の関数・エイリアス・関数URL、早見表の S3 と CloudFront）。
# 器は Terraform、中身（コードと早見表のファイル）は GitHub Actions が届ける。
terraform {
  required_version = "~> 1.16"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7"
    }
  }

  # state は bootstrap/ で作ったバケットに置く（バケット名とリージョンは init のときに渡す）
  #   terraform init -backend-config="bucket=warikan-tfstate-<アカウントID>" -backend-config="region=<リージョン>"
  backend "s3" {
    key          = "infra/terraform.tfstate"
    use_lockfile = true # S3 のロックファイルで、同時に2つの apply が動かないようにする
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "terraform-infra"
    }
  }
}
