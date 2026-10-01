"""割り勘の計算。

合計の金額と人数から、1人あたりの金額を決める。
割り切れない端数は幹事が払う。幹事が多めに払うこともできる。
"""

from dataclasses import dataclass


@dataclass(frozen=True)
class Share:
    """割り勘の結果。"""

    member: int  # 幹事以外の1人が払う金額
    organizer: int  # 幹事が払う金額
    people: int  # 幹事を含む人数

    @property
    def total(self) -> int:
        """全員が払う金額の合計。"""
        return self.member * (self.people - 1) + self.organizer


def _check(total: int, people: int, unit: int) -> None:
    if people < 1:
        raise ValueError("人数は1人以上にしてください")
    if total < 0:
        raise ValueError("合計の金額は0円以上にしてください")
    if unit < 1:
        raise ValueError("切り捨ての単位は1円以上にしてください")


def split(total: int, people: int, unit: int = 1) -> Share:
    """合計 total 円を people 人で割る。

    幹事以外は unit 円単位で切り捨てた金額を払い、残りは幹事が払う。
    例: split(10000, 3) → 幹事以外 3333円、幹事 3334円
    """
    return split_with_extra(total, people, extra=0, unit=unit)


def split_with_extra(total: int, people: int, extra: int, unit: int = 1) -> Share:
    """幹事が extra 円多めに払う割り勘。

    例: split_with_extra(10000, 4, extra=1000) → 幹事以外 2250円、幹事 3250円
    """
    _check(total, people, unit)
    if extra < 0:
        raise ValueError("幹事が多めに払う金額は0円以上にしてください")
    if extra > total:
        raise ValueError("幹事が多めに払う金額が合計を超えています")
    if people == 1:
        return Share(member=0, organizer=total, people=1)

    member = (total - extra) // people // unit * unit
    organizer = total - member * (people - 1)
    return Share(member=member, organizer=organizer, people=people)
