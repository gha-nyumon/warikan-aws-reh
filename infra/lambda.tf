data "aws_caller_identity" "current" {}

# 最初の中身（warikan/ のコード）。2回目からは GitHub Actions がコードを届ける
# zip の中は warikan/calc.py のように warikan/ フォルダごと入れる（ハンドラーが warikan.handler.handler のため）
data "archive_file" "initial" {
  type        = "zip"
  output_path = "${path.module}/.build/initial.zip"

  dynamic "source" {
    for_each = fileset("${path.module}/../warikan", "*.py")
    content {
      content  = file("${path.module}/../warikan/${source.value}")
      filename = "warikan/${source.value}"
    }
  }
}

# ---------------------------------------------------------------------------
# Lambda が動くときの権限（ログを書くだけ）
# ---------------------------------------------------------------------------
resource "aws_iam_role" "lambda" {
  name = "${var.project}-lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project}"
  retention_in_days = var.log_retention_days
}

# ---------------------------------------------------------------------------
# 関数（器）
# ---------------------------------------------------------------------------
resource "aws_lambda_function" "api" {
  function_name = var.project
  role          = aws_iam_role.lambda.arn
  runtime       = "python3.13"
  handler       = "warikan.handler.handler"
  memory_size   = var.lambda_memory_size
  timeout       = 5

  filename         = data.archive_file.initial.output_path
  source_code_hash = data.archive_file.initial.output_base64sha256
  publish          = true # 最初のバージョン（1）を発行する

  depends_on = [aws_iam_role_policy_attachment.lambda_logs, aws_cloudwatch_log_group.lambda]

  lifecycle {
    # 中身（コード）は GitHub Actions が届けるので、Terraform からは変えない
    ignore_changes = [filename, source_code_hash]
  }
}

# ---------------------------------------------------------------------------
# エイリアス（dev・prod）。どのバージョンを指すかは GitHub Actions が決める
# ---------------------------------------------------------------------------
resource "aws_lambda_alias" "env" {
  for_each         = toset(var.environments)
  name             = each.key
  function_name    = aws_lambda_function.api.function_name
  function_version = aws_lambda_function.api.version

  lifecycle {
    ignore_changes = [function_version, routing_config]
  }
}

# ---------------------------------------------------------------------------
# 関数URL（エイリアスごと）。認証なしの公開の API なので、公開してよい計算だけを置く
# ---------------------------------------------------------------------------
resource "aws_lambda_function_url" "env" {
  for_each           = aws_lambda_alias.env
  function_name      = aws_lambda_function.api.function_name
  qualifier          = each.value.name
  authorization_type = "NONE"
}

# 関数URL から誰でも呼べるようにする許可
resource "aws_lambda_permission" "url" {
  for_each               = aws_lambda_alias.env
  statement_id           = "FunctionUrlPublic-${each.key}"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.api.function_name
  qualifier              = each.value.name
  principal              = "*"
  function_url_auth_type = "NONE"
}

# 2025年10月から、新しく作る関数URL には lambda:InvokeFunction の許可も必要（関数URL 経由の呼び出しに限る）
resource "aws_lambda_permission" "url_invoke" {
  for_each                 = aws_lambda_alias.env
  statement_id             = "FunctionUrlInvoke-${each.key}"
  action                   = "lambda:InvokeFunction"
  function_name            = aws_lambda_function.api.function_name
  qualifier                = each.value.name
  principal                = "*"
  invoked_via_function_url = true
}
