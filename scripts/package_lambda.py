"""Lambda に上げる zip（dist/function.zip）を作る。

使い方（リポジトリのいちばん上で）:
    python scripts/package_lambda.py

warikan/ フォルダの .py ファイルだけを入れる（テストや道具は入れない）。
Lambda の関数の「ハンドラー」は warikan.handler.handler。
"""

import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PACKAGE = ROOT / "warikan"
OUT = ROOT / "dist" / "function.zip"


def main() -> None:
    OUT.parent.mkdir(exist_ok=True)
    files = sorted(PACKAGE.glob("*.py"))
    with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED) as z:
        for f in files:
            # 日時を固定して、同じコードなら毎回まったく同じ zip になるようにする
            # （どのコミットでも、コードが同じかどうかを zip の中身で比べられる）
            info = zipfile.ZipInfo(f.relative_to(ROOT).as_posix(), date_time=(2026, 1, 1, 0, 0, 0))
            info.external_attr = 0o644 << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            z.writestr(info, f.read_bytes())
    names = ", ".join(f.relative_to(ROOT).as_posix() for f in files)
    print(f"{OUT.relative_to(ROOT)} を作りました（{names}）")


if __name__ == "__main__":
    main()
