import json

from warikan.handler import handler


def call(**params):
    event = {"queryStringParameters": {k: str(v) for k, v in params.items()}}
    res = handler(event, None)
    return res["statusCode"], json.loads(res["body"])


def test_APIで割り勘を計算する():
    status, body = call(total=10000, people=3)
    assert status == 200
    assert body["member"] == 3333
    assert body["organizer"] == 3334
    assert body["total"] == 10000


def test_APIで単位と多めの金額を指定する():
    status, body = call(total=10000, people=4, unit=100, extra=1000)
    assert status == 200
    assert body["member"] == 2200
    assert body["organizer"] == 3400
    assert body["unit"] == 100


def test_APIで人数が無いと400():
    status, body = call(total=10000)
    assert status == 400
    assert "people" in body["error"]


def test_APIで整数でないと400():
    status, body = call(total="abc", people=3)
    assert status == 400


def test_APIでクエリが無いと400():
    res = handler({}, None)
    assert res["statusCode"] == 400
