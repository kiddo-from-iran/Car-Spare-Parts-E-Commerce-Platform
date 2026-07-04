from fastapi import APIRouter, Depends

from auth_utils import require_admin
from database import get_conn

admin_stats_router = APIRouter(prefix="/api/admin/stats", tags=["admin-stats"])

STATUS_LABELS = {
    "pending_payment": "در انتظار پرداخت",
    "processing": "در حال پردازش",
    "shipped": "ارسال شده",
    "delivered": "تحویل داده شده",
    "cancelled": "لغو شده",
}


@admin_stats_router.get("")
def get_dashboard_stats(_: dict = Depends(require_admin)):
    conn = get_conn()
    cur = conn.cursor()

    total_sales = cur.execute(
        "SELECT COALESCE(SUM(total), 0) FROM orders WHERE status NOT IN ('cancelled')"
    ).fetchone()[0]
    today_sales = cur.execute(
        "SELECT COALESCE(SUM(total), 0) FROM orders WHERE date(created_at) = date('now') AND status NOT IN ('cancelled')"
    ).fetchone()[0]
    month_sales = cur.execute(
        "SELECT COALESCE(SUM(total), 0) FROM orders WHERE strftime('%Y-%m', created_at) = strftime('%Y-%m', 'now') AND status NOT IN ('cancelled')"
    ).fetchone()[0]
    total_orders = cur.execute("SELECT COUNT(*) FROM orders").fetchone()[0]
    pending_orders = cur.execute(
        "SELECT COUNT(*) FROM orders WHERE status IN ('pending_payment', 'processing')"
    ).fetchone()[0]
    processing_orders = cur.execute(
        "SELECT COUNT(*) FROM orders WHERE status = 'processing'"
    ).fetchone()[0]
    in_transit_orders = cur.execute(
        "SELECT COUNT(*) FROM orders WHERE status = 'shipped'"
    ).fetchone()[0]
    completed_orders = cur.execute(
        "SELECT COUNT(*) FROM orders WHERE status = 'delivered'"
    ).fetchone()[0]
    cancelled_orders = cur.execute(
        "SELECT COUNT(*) FROM orders WHERE status = 'cancelled'"
    ).fetchone()[0]
    total_customers = cur.execute("SELECT COUNT(*) FROM users WHERE role = 'user'").fetchone()[0]
    total_products = cur.execute("SELECT COUNT(*) FROM products").fetchone()[0]
    low_stock = cur.execute(
        "SELECT COUNT(*) FROM products WHERE stock_quantity > 0 AND stock_quantity <= 5"
    ).fetchone()[0]
    out_of_stock = cur.execute(
        "SELECT COUNT(*) FROM products WHERE in_stock = 0 OR stock_quantity = 0"
    ).fetchone()[0]
    open_tickets = cur.execute(
        "SELECT COUNT(*) FROM tickets WHERE status = 'open'"
    ).fetchone()[0]

    recent_orders = [
        {
            **dict(r),
            "status_label": STATUS_LABELS.get(r["status"], r["status"]),
        }
        for r in cur.execute(
            """SELECT o.id, o.order_number, o.total, o.status, o.created_at, u.full_name as user_name
               FROM orders o JOIN users u ON u.id = o.user_id
               ORDER BY o.created_at DESC LIMIT 8"""
        ).fetchall()
    ]

    pending_tickets = [
        dict(r)
        for r in cur.execute(
            """SELECT t.id, t.subject, u.full_name as user_name
               FROM tickets t JOIN users u ON u.id = t.user_id
               WHERE t.status = 'open' ORDER BY t.updated_at DESC LIMIT 8"""
        ).fetchall()
    ]

    low_stock_items = [dict(r) for r in cur.execute(
        """SELECT id, name, price, stock_quantity FROM products
           WHERE stock_quantity > 0 AND stock_quantity <= 5
           ORDER BY stock_quantity ASC LIMIT 8"""
    ).fetchall()]

    conn.close()

    return {
        "total_sales": total_sales,
        "today_sales": today_sales,
        "month_sales": month_sales,
        "total_orders": total_orders,
        "pending_orders": pending_orders,
        "processing_orders": processing_orders,
        "in_transit_orders": in_transit_orders,
        "completed_orders": completed_orders,
        "cancelled_orders": cancelled_orders,
        "total_customers": total_customers,
        "total_products": total_products,
        "low_stock_products": low_stock,
        "out_of_stock_products": out_of_stock,
        "open_tickets": open_tickets,
        "recent_orders": recent_orders,
        "pending_tickets": pending_tickets,
        "low_stock_items": low_stock_items,
    }
