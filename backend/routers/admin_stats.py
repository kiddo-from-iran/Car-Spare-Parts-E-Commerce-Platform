from fastapi import APIRouter, Depends

from auth_utils import require_admin
from database import get_conn

admin_stats_router = APIRouter(prefix="/api/admin/stats", tags=["admin-stats"])


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
    completed_orders = cur.execute(
        "SELECT COUNT(*) FROM orders WHERE status = 'delivered'"
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

    conn.close()

    return {
        "total_sales": total_sales,
        "today_sales": today_sales,
        "month_sales": month_sales,
        "total_orders": total_orders,
        "pending_orders": pending_orders,
        "completed_orders": completed_orders,
        "total_customers": total_customers,
        "total_products": total_products,
        "low_stock_products": low_stock,
        "out_of_stock_products": out_of_stock,
        "open_tickets": open_tickets,
    }
