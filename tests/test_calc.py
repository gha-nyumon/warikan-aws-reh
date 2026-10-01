import pytest

from warikan.calc import split, split_with_extra


def test_割り切れる():
    share = split(9000, 3)
    assert share.member == 3000
    assert share.organizer == 3000


def test_端数を幹事が払う():
    share = split(10000, 3)
    assert share.member == 3333
    assert share.organizer == 3334


def test_合計が変わらない():
    share = split(10000, 7)
    assert share.total == 10000


def test_100円単位で切り捨てる():
    share = split(10000, 3, unit=100)
    assert share.member == 3300
    assert share.organizer == 3400


def test_1人なら全額を幹事が払う():
    share = split(5000, 1)
    assert share.member == 0
    assert share.organizer == 5000


def test_幹事が多めに払う():
    share = split_with_extra(10000, 4, extra=1000)
    assert share.member == 2250
    assert share.organizer == 3250


def test_幹事が多めに払う_100円単位():
    share = split_with_extra(12345, 4, extra=1000, unit=100)
    assert share.member == 2800
    assert share.organizer == 3945
    assert share.total == 12345


def test_0円():
    share = split(0, 5)
    assert share.member == 0
    assert share.organizer == 0


@pytest.mark.parametrize("people", [0, -1])
def test_人数が0人以下はエラー(people):
    with pytest.raises(ValueError):
        split(10000, people)


def test_多めに払う金額が合計を超えるとエラー():
    with pytest.raises(ValueError):
        split_with_extra(1000, 2, extra=2000)
