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
    # アプリを dev に届ける。環境 dev を指定したジョブだけが借りられる
    deploy-dev = {
      subs        = ["${local.repo_sub}:environment:dev"]
      max_session = 3600
    }
    # アプリを prod に届ける。環境 prod を指定したジョブだけが借りられる（prod は承認してから始まる）
    deploy-prod = {
      subs        = ["${local.repo_sub}:environment:prod"]
      max_session = 3600
    }
  }

  # infra/ で作るものの名前（infra/ と同じ決まり）
  function_arn = "arn:aws:lambda:${var.region}:${local.account_id}:function:${var.project}"
  site_bucket  = "${var.project}-site-${local.account_id}"

  # 1つの環境（エイリアスと、早見表のフォルダ）に届けるための権限
  deploy_statements = {
    for env in ["dev", "prod"] : env => [
      {
        Sid      = "LambdaCode"
        Effect   = "Allow"
        Action   = ["lambda:GetFunction", "lambda:UpdateFunctionCode", "lambda:PublishVersion"]
        Resource = local.function_arn
      },
      {
        # エイリアスの操作は、関数そのもの（エイリアスの名前の付かない ARN）に対して許可を確かめる仕組みのため、
        # dev と prod のエイリアスを IAM で分けることはできない（2026-09-30 リハーサルで確認）。環境は S3 のフォルダと信頼ポリシーで分ける
        Sid      = "LambdaAlias"
        Effect   = "Allow"
        Action   = ["lambda:GetAlias", "lambda:UpdateAlias"]
        Resource = local.function_arn
      },
      {
        # スモークテストで、発行したバージョンを直接呼ぶ
        Sid      = "LambdaInvokeVersion"
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction"]
        Resource = "${local.function_arn}:*"
      },
      {
        Sid      = "SiteList"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::${local.site_bucket}"
        Condition = {
          StringLike = { "s3:prefix" = ["${env}/*", "${env}/"] }
        }
      },
      {
        Sid      = "SiteWrite"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "arn:aws:s3:::${local.site_bucket}/${env}/*"
      },
      {
        # CloudFront のディストリビューションは infra/ で作るので、ID はここでは決まっていない（アカウントに1つの想定）
        Sid      = "Invalidate"
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation", "cloudfront:GetInvalidation"]
        Resource = "arn:aws:cloudfront::${local.account_id}:distribution/*"
      },
    ]
  }

  # ロールごとの権限ポリシー（whoami には付けない）
  gha_policies = {
    deploy-dev  = local.deploy_statements["dev"]
    deploy-prod = local.deploy_statements["prod"]
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

resource "aws_iam_role_policy" "gha" {
  for_each = local.gha_policies
  name     = "${var.project}-${each.key}"
  role     = aws_iam_role.gha[each.key].id
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = each.value
  })
}

output "gha_role_arns" {
  description = "GitHub の変数に登録するロールの ARN"
  value       = { for k, r in aws_iam_role.gha : k => r.arn }
}
