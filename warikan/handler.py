"""割り勘計算の API（AWS Lambda の関数URL から呼ばれる入口）。

呼び方の例:
    https://<関数URL>/?total=10000&people=3
    https://<関数URL>/?total=10000&people=3&unit=100&extra=1000

返す値（JSON）:
    {"member": 3333, "organizer": 3334, "people": 3, "total": 10000, "unit": 1, "version": "5"}
    member は幹事以外の1人が払う金額、organizer は幹事が払う金額、
    version は答えた Lambda のバージョン。
"""

import json
import os

from warikan.calc import split_with_extra


def _response(status: int, body: dict) -> dict:
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json; charset=utf-8"},
        "body": json.dumps(body, ensure_ascii=False),
    }


def _int_param(params: dict, name: str, default: int | None = None) -> int:
    value = params.get(name)
    if value is None or value == "":
        if default is None:
            raise ValueError(f"{name} を指定してください")
        return default
    try:
        return int(value)
    except ValueError:
        raise ValueError(f"{name} は整数で指定してください") from None


def handler(event: dict, context: object) -> dict:
    """関数URL のイベント（クエリ文字列）から割り勘を計算して返す。"""
    params = event.get("queryStringParameters") or {}
    try:
        total = _int_param(params, "total")
        people = _int_param(params, "people")
        unit = _int_param(params, "unit", 1)
        extra = _int_param(params, "extra", 0)
        share = split_with_extra(total, people, extra=extra, unit=unit)
    except ValueError as e:
        return _response(400, {"error": str(e)})

    member = share.member
    # わざと入れた誤り: 11人以上だと幹事以外が0円になる（テストもスモークテストも試さない人数）
    if people >= 11:
        member = 0

    return _response(
        200,
        {
            "member": member,
            "organizer": share.organizer,
            "people": share.people,
            "total": share.total,
            "unit": unit,
            "version": os.environ.get("AWS_LAMBDA_FUNCTION_VERSION", "local"),
        },
    )
