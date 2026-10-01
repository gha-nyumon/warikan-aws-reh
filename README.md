# 割り勘計算（warikan-aws）

「GitHub Actions × AWS CI/CD 実践」のハンズオンで育てるリポジトリです。
合計の金額と人数から1人あたりの金額を計算するアプリを、**計算の API（AWS Lambda の関数URL）**と、**早見表のページ（S3＋CloudFront）**として AWS に届けます。
テストと書き方のチェック（lint）の自動化までは、はじめから入っています。

## 中身

| ファイル・フォルダ | 役割 |
|---|---|
| `warikan/calc.py` | 割り勘の計算 |
| `warikan/handler.py` | Lambda の入口（関数URL のクエリ `total`・`people`・`unit`・`extra` を受け取り、JSON で返す） |
| `tests/` | pytest のテスト |
| `scripts/build_site.py` | 早見表（金額 × 人数）の HTML を `site/` に書き出す |
| `scripts/package_lambda.py` | Lambda に上げる zip を `dist/function.zip` に作る |
| `.github/workflows/ci.yml` | プルリクエストと main への push で、ruff と pytest を動かす |
| `bootstrap/` | Terraform：すべての土台（GitHub の OIDC プロバイダー・state の置き場所・GitHub Actions が借りるロール）。**CloudShell から apply する** |
| `infra/` | Terraform：アプリを載せるもの（Lambda の関数・エイリアス dev と prod・関数URL、早見表の S3 と CloudFront） |

`.github/` と `bootstrap/` は、ハンズオンで1つずつ育てます。

## 使い方

1. このリポジトリの右上の **Use this template** → **Create a new repository** で、自分のリポジトリを作ります（**公開（Public）**で作ってください。承認の設定を無料で使うためです）。
2. AWS の CloudShell で、ハンズオン1 の手順に沿って `bootstrap/` → `infra/` の順に `terraform apply` します。アクセスキーは作りません。

## API の例

```
https://<関数URL>/?total=10000&people=3
→ {"member": 3333, "organizer": 3334, "people": 3, "total": 10000, "version": "1"}
```

## 手元で動かす（任意。コースはブラウザと CloudShell だけで進められます）

```bash
pip install -r requirements-dev.txt
ruff check . && ruff format --check .   # 書き方のチェック
pytest                                  # テスト
python scripts/build_site.py            # 早見表を site/index.html に書き出す
python scripts/package_lambda.py        # Lambda に上げる zip を dist/function.zip に作る
```

## 後片付け

学習が終わったら、`infra/` → `bootstrap/` の順に `terraform destroy` してください（土台は最後に消す）。
