variable "region" {
  description = "使うリージョン（bootstrap/ と同じ）"
  type        = string
}

variable "project" {
  description = "リソースの名前の先頭に付ける名前"
  type        = string
  default     = "warikan"
}

variable "environments" {
  description = "Lambda のエイリアスと、早見表の置き場所（S3 のフォルダ）の名前"
  type        = list(string)
  default     = ["dev", "prod"]
}

variable "lambda_memory_size" {
  description = "Lambda のメモリ（MB）"
  type        = number
  default     = 128
}

variable "log_retention_days" {
  description = "Lambda のログを残す日数"
  type        = number
  default     = 14
}
