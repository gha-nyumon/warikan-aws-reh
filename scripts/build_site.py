"""割り勘の早見表（金額 × 人数）の HTML を site/ に書き出す。

使い方（リポジトリのいちばん上で）:
    python scripts/build_site.py
"""

import datetime
import html
import sys
from pathlib import Path

# scripts/ の1つ上（リポジトリのいちばん上）から warikan を読み込めるようにする
ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from warikan.calc import split  # noqa: E402

AMOUNTS = [3000, 5000, 8000, 10000, 12000, 15000, 20000, 30000, 40000, 50000]
PEOPLE = [2, 3, 4, 5, 6, 8, 10]
OUT_DIR = ROOT / "site"


def cell(total: int, people: int) -> str:
    share = split(total, people, unit=100)
    if share.member == share.organizer:
        return f"<td>{share.member:,}円</td>"
    return f'<td>{share.member:,}円<span class="org">幹事 {share.organizer:,}円</span></td>'


def build_html() -> str:
    head = "".join(f"<th>{n}人</th>" for n in PEOPLE)
    rows = []
    for total in AMOUNTS:
        cells = "".join(cell(total, n) for n in PEOPLE)
        rows.append(f"<tr><th>{total:,}円</th>{cells}</tr>")
    today = datetime.date.today().isoformat()
    title = html.escape("割り勘の早見表")
    return f"""<!doctype html>
<html lang="ja">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title}</title>
<style>
  body {{ font-family: "Meiryo", "Hiragino Sans", sans-serif; margin: 2rem; color: #222; }}
  h1 {{ font-size: 1.6rem; }}
  table {{ border-collapse: collapse; }}
  th, td {{ border: 1px solid #ccc; padding: .5rem .8rem; text-align: right; }}
  thead th {{ background: #1f6feb; color: #fff; }}
  tbody th {{ background: #f0f4fa; }}
  .org {{ display: block; font-size: .8rem; color: #b35900; }}
  .note {{ color: #555; font-size: .9rem; }}
</style>
</head>
<body>
<h1>{title}</h1>
<p class="note">1人あたりの金額（100円単位で切り捨て。端数は幹事が払います）</p>
<table>
<thead><tr><th>合計＼人数</th>{head}</tr></thead>
<tbody>
{chr(10).join(rows)}
</tbody>
</table>
<p class="note">更新日: {today}</p>
</body>
</html>
"""


def main() -> None:
    OUT_DIR.mkdir(exist_ok=True)
    out = OUT_DIR / "index.html"
    out.write_text(build_html(), encoding="utf-8")
    print(f"{out.relative_to(ROOT)} を書き出しました")


if __name__ == "__main__":
    main()
