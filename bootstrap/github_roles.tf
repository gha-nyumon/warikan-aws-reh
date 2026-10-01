# ---------------------------------------------------------------------------
# GitHub Actions が OIDC で借りるロール
#   信頼ポリシー（誰が借りてよいか）: aud = sts.amazonaws.com、sub = 用途ごとに狭く
#   権限ポリシー（借りたら何をしてよいか）: 用途ごとに、対象のリソースだけ
# ---------------------------------------------------------------------------
locals {
  gha_roles = {
    # 動作確認用。main ブランチで動いたジョブだけが借りられる。権限は何も付けない（自分がだれかを確かめるだけ）
    whoami = {
      subs        = ["${local.repo_sub}:ref:refs/heads/main"]
      max_session = 3600
    }
  }
}

resource "aws_iam_role" "gha" {
  for_each             = local.gha_roles
  name                 = "${var.project}-${each.key}"
  max_session_duration = each.value.max_session

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = each.value.subs
        }
      }
    }]
  })
}

output "gha_role_arns" {
  description = "GitHub の変数に登録するロールの ARN"
  value       = { for k, r in aws_iam_role.gha : k => r.arn }
}
