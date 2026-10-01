output "function_name" {
  value = aws_lambda_function.api.function_name
}

output "api_urls" {
  description = "環境ごとの関数URL（API）"
  value       = { for k, v in aws_lambda_function_url.env : k => v.function_url }
}

output "site_bucket" {
  value = aws_s3_bucket.site.bucket
}

output "distribution_id" {
  value = aws_cloudfront_distribution.site.id
}

output "site_urls" {
  description = "環境ごとの早見表の URL"
  value       = { for e in var.environments : e => "https://${aws_cloudfront_distribution.site.domain_name}/${e}/index.html" }
}
