from fastapi import APIRouter

from database import get_conn
from models import DiscountValidateRequest, DiscountValidateResponse

router = APIRouter(prefix="/api/discount", tags=["discount"])


def calculate_discount(code_row, subtotal: float) -> float:
    if subtotal < code_row["min_order"]:
        return 0
    if code_row["discount_type"] == "percent":
        return round(subtotal * code_row["value"] / 100, 2)
    return min(code_row["value"], subtotal)


@router.post("/validate", response_model=DiscountValidateResponse)
def validate_discount(data: DiscountValidateRequest):
    code = data.code.strip().upper()
    conn = get_conn()
    row = conn.execute(
        "SELECT * FROM discount_codes WHERE code = ? AND active = 1",
        (code,),
    ).fetchone()
    conn.close()

    if row is None:
        return DiscountValidateResponse(
            valid=False,
            code=code,
            discount_amount=0,
            message="کد تخفیف نامعتبر است",
        )

    if row["max_uses"] is not None and row["used_count"] >= row["max_uses"]:
        return DiscountValidateResponse(
            valid=False,
            code=code,
            discount_amount=0,
            message="ظرفیت استفاده از این کد تمام شده",
        )

    amount = calculate_discount(row, data.subtotal)
    if amount <= 0:
        return DiscountValidateResponse(
            valid=False,
            code=code,
            discount_amount=0,
            message=f"حداقل مبلغ سفارش {int(row['min_order']):,} تومان است",
        )

    return DiscountValidateResponse(
        valid=True,
        code=code,
        discount_amount=amount,
        message="کد تخفیف اعمال شد",
    )
