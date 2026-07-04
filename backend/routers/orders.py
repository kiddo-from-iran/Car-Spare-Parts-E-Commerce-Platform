import uuid
from collections import defaultdict
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query

from auth_utils import get_current_user, require_admin
from constants import (
    ACTIVE_STATUSES,
    COMPLETED_STATUSES,
    ORDER_STATUS_LABELS,
    SHIPPING_COSTS,
    SHIPPING_LABELS,
    OrderStatus,
    normalize_order_status,
    order_status_label,
)
from database import get_conn
from models import CheckoutRequest, CheckoutResponse, OrderItemOut, OrderOut, OrderStatusUpdate, RevenueSummary, MonthlyRevenue
from routers.discounts import calculate_discount

router = APIRouter(prefix="/api/orders", tags=["orders"])


def _split_user_name(full_name: str) -> tuple[str, str]:
    parts = (full_name or "").strip().split(None, 1)
    if not parts:
        return ("", "")
    if len(parts) == 1:
        return (parts[0], "")
    return (parts[0], parts[1])


def _row_val(row, key, default=None):
    try:
        val = row[key]
        return default if val is None else val
    except (KeyError, IndexError):
        return default


def _build_order(row, items_rows, user_row) -> OrderOut:
    items = [
        OrderItemOut(
            id=i["id"],
            product_id=i["product_id"],
            product_name=i["product_name"],
            quantity=i["quantity"],
            color=i["color"],
            size=i["size"],
            unit_price=i["unit_price"],
            line_total=i["unit_price"] * i["quantity"],
        )
        for i in items_rows
    ]
    status = normalize_order_status(row["status"])
    subtotal = _row_val(row, "subtotal", row["total"])
    discount_amount = _row_val(row, "discount_amount", 0.0)
    shipping_cost = _row_val(row, "shipping_cost", 0.0)
    shipping_method = _row_val(row, "shipping_method", "post")
    return OrderOut(
        id=row["id"],
        order_number=row["order_number"],
        user_id=row["user_id"],
        user_name=user_row["full_name"],
        user_phone=_row_val(user_row, "phone", ""),
        user_email=user_row["email"],
        status=status,
        status_label=order_status_label(status),
        subtotal=subtotal,
        discount_code=_row_val(row, "discount_code"),
        discount_amount=discount_amount,
        shipping_method=shipping_method,
        shipping_cost=shipping_cost,
        total=row["total"],
        phone=_row_val(row, "phone", _row_val(user_row, "phone", "")),
        first_name=row["first_name"],
        last_name=row["last_name"],
        address=row["address"],
        city=row["city"],
        state=row["state"],
        zip_code=row["zip_code"],
        country=row["country"],
        created_at=row["created_at"],
        updated_at=row["updated_at"],
        items=items,
    )


def _fetch_order(conn, order_id: int) -> OrderOut:
    row = conn.execute("SELECT * FROM orders WHERE id = ?", (order_id,)).fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="سفارش یافت نشد")
    items = conn.execute("SELECT * FROM order_items WHERE order_id = ?", (order_id,)).fetchall()
    user = conn.execute("SELECT full_name, phone, email FROM users WHERE id = ?", (row["user_id"],)).fetchone()
    return _build_order(row, items, user)


@router.post("/checkout", response_model=CheckoutResponse)
def checkout(data: CheckoutRequest, user: dict = Depends(get_current_user)):
    if not data.items:
        raise HTTPException(status_code=400, detail="سبد خرید خالی است")

    if data.shipping_method not in SHIPPING_COSTS:
        raise HTTPException(status_code=400, detail="روش ارسال نامعتبر است")

    conn = get_conn()
    subtotal = 0.0
    order_items = []
    qty_by_product: dict[int, int] = defaultdict(int)

    for item in data.items:
        if item.quantity <= 0:
            conn.close()
            raise HTTPException(status_code=400, detail="تعداد نامعتبر است")
        qty_by_product[item.product_id] += item.quantity

    products_by_id: dict[int, dict] = {}
    for product_id, total_qty in qty_by_product.items():
        product = conn.execute("SELECT * FROM products WHERE id = ?", (product_id,)).fetchone()
        if product is None:
            conn.close()
            raise HTTPException(status_code=400, detail=f"محصول {product_id} یافت نشد")
        stock = int(product["stock_quantity"] if product["stock_quantity"] is not None else 0)
        if not product["in_stock"] or stock <= 0:
            conn.close()
            raise HTTPException(status_code=400, detail=f"محصول {product['name']} موجود نیست")
        if total_qty > stock:
            conn.close()
            raise HTTPException(
                status_code=400,
                detail=f"موجودی «{product['name']}» کافی نیست. موجود: {stock} عدد",
            )
        products_by_id[product_id] = product

    for item in data.items:
        product = products_by_id[item.product_id]
        line = product["price"] * item.quantity
        subtotal += line
        order_items.append((product, item))

    first_name = data.first_name
    last_name = data.last_name
    address = data.address
    city = data.city
    state = data.state
    zip_code = data.zip_code
    country = data.country
    saved_address_id = data.saved_address_id

    if data.saved_address_id:
        addr = conn.execute(
            "SELECT * FROM user_addresses WHERE id = ? AND user_id = ?",
            (data.saved_address_id, user["id"]),
        ).fetchone()
        if addr is None:
            conn.close()
            raise HTTPException(status_code=400, detail="آدرس ذخیره‌شده یافت نشد")
        first_name = addr["first_name"] or _split_user_name(user.get("full_name", ""))[0]
        last_name = addr["last_name"] or _split_user_name(user.get("full_name", ""))[1]
        address = addr["address"]
        city = addr["city"] or "—"
        state = addr["state"] or "—"
        zip_code = addr["zip_code"] or "—"
        country = addr["country"] or "ایران"
        saved_address_id = addr["id"]
    elif not address.strip():
        conn.close()
        raise HTTPException(status_code=400, detail="آدرس ارسال الزامی است")
    else:
        default_fn, default_ln = _split_user_name(user.get("full_name", ""))
        first_name = first_name.strip() or default_fn
        last_name = last_name.strip() or default_ln
        city = city.strip() or "—"
        state = state.strip() or "—"
        zip_code = zip_code.strip() or "—"

    discount_code = None
    discount_amount = 0.0
    if data.discount_code:
        code = data.discount_code.strip().upper()
        code_row = conn.execute(
            "SELECT * FROM discount_codes WHERE code = ? AND active = 1",
            (code,),
        ).fetchone()
        if code_row is None:
            conn.close()
            raise HTTPException(status_code=400, detail="کد تخفیف نامعتبر است")
        if code_row["max_uses"] is not None and code_row["used_count"] >= code_row["max_uses"]:
            conn.close()
            raise HTTPException(status_code=400, detail="ظرفیت استفاده از این کد تمام شده")
        discount_amount = calculate_discount(code_row, subtotal)
        if discount_amount <= 0:
            conn.close()
            raise HTTPException(
                status_code=400,
                detail=f"حداقل مبلغ سفارش {int(code_row['min_order']):,} تومان است",
            )
        discount_code = code

    shipping_cost = SHIPPING_COSTS[data.shipping_method]
    total = round(subtotal - discount_amount + shipping_cost, 2)

    now = datetime.now().isoformat()
    order_number = f"ORD-{uuid.uuid4().hex[:8].upper()}"
    cur = conn.cursor()
    cur.execute(
        """INSERT INTO orders
        (order_number, user_id, status, subtotal, discount_code, discount_amount,
         shipping_method, shipping_cost, total, phone, email, first_name, last_name,
         address, city, state, zip_code, country, saved_address_id, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (
            order_number,
            user["id"],
            OrderStatus.PENDING_PAYMENT.value,
            subtotal,
            discount_code,
            discount_amount,
            data.shipping_method,
            shipping_cost,
            total,
            user["phone"],
            user.get("email") or "",
            first_name,
            last_name,
            address,
            city,
            state,
            zip_code,
            country,
            saved_address_id,
            now,
            now,
        ),
    )
    order_id = cur.lastrowid

    for product, item in order_items:
        cur.execute(
            """INSERT INTO order_items
            (order_id, product_id, product_name, quantity, color, size, unit_price)
            VALUES (?, ?, ?, ?, ?, ?, ?)""",
            (
                order_id,
                product["id"],
                product["name"],
                item.quantity,
                item.color,
                item.size,
                product["price"],
            ),
        )

    for product_id, total_qty in qty_by_product.items():
        product = products_by_id[product_id]
        current_stock = int(product["stock_quantity"] if product["stock_quantity"] is not None else 0)
        new_stock = max(current_stock - total_qty, 0)
        cur.execute(
            "UPDATE products SET stock_quantity = ?, in_stock = ? WHERE id = ?",
            (new_stock, 1 if new_stock > 0 else 0, product_id),
        )

    if discount_code:
        conn.execute(
            "UPDATE discount_codes SET used_count = used_count + 1 WHERE code = ?",
            (discount_code,),
        )

    conn.commit()
    conn.close()
    return CheckoutResponse(
        order_id=order_number,
        message="سفارش با موفقیت ثبت شد. از خرید شما سپاسگزاریم!",
        subtotal=round(subtotal, 2),
        discount_amount=discount_amount,
        shipping_cost=shipping_cost,
        total=total,
    )


@router.get("/my", response_model=list[OrderOut])
def my_orders(user: dict = Depends(get_current_user)):
    conn = get_conn()
    rows = conn.execute(
        "SELECT * FROM orders WHERE user_id = ? ORDER BY created_at DESC",
        (user["id"],),
    ).fetchall()
    orders = []
    for row in rows:
        items = conn.execute("SELECT * FROM order_items WHERE order_id = ?", (row["id"],)).fetchall()
        user_row = conn.execute(
            "SELECT full_name, phone, email FROM users WHERE id = ?", (row["user_id"],)
        ).fetchone()
        orders.append(_build_order(row, items, user_row))
    conn.close()
    return orders


@router.get("/my/{order_id}", response_model=OrderOut)
def my_order_detail(order_id: int, user: dict = Depends(get_current_user)):
    conn = get_conn()
    row = conn.execute(
        "SELECT * FROM orders WHERE id = ? AND user_id = ?",
        (order_id, user["id"]),
    ).fetchone()
    if row is None:
        conn.close()
        raise HTTPException(status_code=404, detail="سفارش یافت نشد")
    items = conn.execute("SELECT * FROM order_items WHERE order_id = ?", (order_id,)).fetchall()
    user_row = conn.execute(
        "SELECT full_name, phone, email FROM users WHERE id = ?", (row["user_id"],)
    ).fetchone()
    conn.close()
    return _build_order(row, items, user_row)


admin_router = APIRouter(prefix="/api/admin/orders", tags=["admin-orders"])

PERSIAN_MONTHS = [
    "", "فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور",
    "مهر", "آبان", "آذر", "دی", "بهمن", "اسفند",
]


@admin_router.get("", response_model=list[OrderOut])
def admin_list_orders(
    filter: Optional[str] = Query(None, description="active|completed|all"),
    status: Optional[str] = None,
    _: dict = Depends(require_admin),
):
    conn = get_conn()
    query = "SELECT * FROM orders WHERE 1=1"
    params: list = []

    if filter == "active":
        placeholders = ",".join("?" * len(ACTIVE_STATUSES))
        query += f" AND status IN ({placeholders})"
        params.extend([s.value for s in ACTIVE_STATUSES])
    elif filter == "completed":
        placeholders = ",".join("?" * len(COMPLETED_STATUSES))
        query += f" AND status IN ({placeholders})"
        params.extend([s.value for s in COMPLETED_STATUSES])

    if status:
        query += " AND status = ?"
        params.append(status)

    query += " ORDER BY created_at DESC"
    rows = conn.execute(query, params).fetchall()
    orders = []
    for row in rows:
        items = conn.execute("SELECT * FROM order_items WHERE order_id = ?", (row["id"],)).fetchall()
        user_row = conn.execute(
            "SELECT full_name, phone, email FROM users WHERE id = ?", (row["user_id"],)
        ).fetchone()
        orders.append(_build_order(row, items, user_row))
    conn.close()
    return orders


@admin_router.patch("/{order_id}/status", response_model=OrderOut)
def update_order_status(order_id: int, data: OrderStatusUpdate, _: dict = Depends(require_admin)):
    try:
        OrderStatus(data.status)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="وضعیت نامعتبر") from exc

    conn = get_conn()
    row = conn.execute("SELECT id FROM orders WHERE id = ?", (order_id,)).fetchone()
    if row is None:
        conn.close()
        raise HTTPException(status_code=404, detail="سفارش یافت نشد")

    now = datetime.now().isoformat()
    conn.execute(
        "UPDATE orders SET status = ?, updated_at = ? WHERE id = ?",
        (data.status, now, order_id),
    )
    conn.commit()
    order = _fetch_order(conn, order_id)
    conn.close()
    return order


@admin_router.delete("/{order_id}")
def delete_order(order_id: int, _: dict = Depends(require_admin)):
    conn = get_conn()
    row = conn.execute("SELECT id FROM orders WHERE id = ?", (order_id,)).fetchone()
    if row is None:
        conn.close()
        raise HTTPException(status_code=404, detail="سفارش یافت نشد")
    conn.execute("DELETE FROM order_items WHERE order_id = ?", (order_id,))
    conn.execute("DELETE FROM orders WHERE id = ?", (order_id,))
    conn.commit()
    conn.close()
    return {"ok": True}


@admin_router.get("/revenue/summary", response_model=RevenueSummary)
def revenue_summary(months: int = 6, _: dict = Depends(require_admin)):
    conn = get_conn()
    rows = conn.execute(
        """SELECT strftime('%Y', created_at) as y, strftime('%m', created_at) as m,
           COUNT(*) as cnt, SUM(total) as rev
           FROM orders WHERE status = 'delivered'
           GROUP BY y, m ORDER BY y DESC, m DESC LIMIT ?""",
        (months,),
    ).fetchall()
    conn.close()

    month_data = []
    total_rev = 0.0
    total_orders = 0
    for row in rows:
        year = int(row["y"])
        month = int(row["m"])
        rev = row["rev"] or 0
        cnt = row["cnt"]
        total_rev += rev
        total_orders += cnt
        month_data.append(
            MonthlyRevenue(
                year=year,
                month=month,
                month_label=f"{PERSIAN_MONTHS[month]} {year}",
                order_count=cnt,
                revenue=round(rev, 2),
            )
        )

    return RevenueSummary(
        months=month_data,
        total_revenue=round(total_rev, 2),
        total_orders=total_orders,
    )
