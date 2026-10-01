data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  # OIDC のトークンの sub の先頭（2026年の新しい形式：名前＋番号）
  # 例: repo:my-team@1234567/warikan-aws@98765432
  repo_sub = "repo:${var.github_owner}@${var.github_owner_id}/${var.github_repo}@${var.github_repo_id}"
}

# ---------------------------------------------------------------------------
# GitHub の OIDC プロバイダー（1つのアカウントに1つ）
# 証明書の指紋（thumbprint）は指定しなくてよい（AWS が自動で確かめる）
# ---------------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

# ---------------------------------------------------------------------------
# Terraform の state の置き場所（infra/ が使う）
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "tfstate" {
  bucket        = "${var.project}-tfstate-${local.account_id}"
  force_destroy = true # 後片付けで中身（前のバージョンも）ごと消せるようにする
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
