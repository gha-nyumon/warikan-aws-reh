output "account_id" {
  value = local.account_id
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github.arn
}

output "tfstate_bucket" {
  description = "infra/ の terraform init で -backend-config に渡すバケット名"
  value       = aws_s3_bucket.tfstate.bucket
}

output "repo_sub" {
  description = "信頼ポリシーの sub の先頭（新しい形式）"
  value       = local.repo_sub
}
