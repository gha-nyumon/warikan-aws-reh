variable "region" {
  description = "使うリージョン（CloudShell の画面の右上と同じにする）"
  type        = string
}

variable "project" {
  description = "リソースの名前の先頭に付ける名前"
  type        = string
  default     = "warikan"
}

variable "github_owner" {
  description = "GitHub のリポジトリの所有者（ユーザー名または Organization 名）"
  type        = string
}

variable "github_owner_id" {
  description = "所有者の番号（ID）。curl -s https://api.github.com/repos/所有者/リポジトリ | jq .owner.id"
  type        = number
}

variable "github_repo" {
  description = "リポジトリの名前"
  type        = string
}

variable "github_repo_id" {
  description = "リポジトリの番号（ID）。curl -s https://api.github.com/repos/所有者/リポジトリ | jq .id"
  type        = number
}
