from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException

from auth_utils import get_current_user, require_admin
from database import get_conn
from models import TicketCreate, TicketMessageCreate, TicketMessageOut, TicketOut

router = APIRouter(prefix="/api/tickets", tags=["tickets"])
admin_router = APIRouter(prefix="/api/admin/tickets", tags=["admin-tickets"])


def _build_ticket(conn, ticket_row, include_messages: bool = True) -> TicketOut:
    order = conn.execute(
        "SELECT order_number FROM orders WHERE id = ?", (ticket_row["order_id"],)
    ).fetchone()
    user = conn.execute(
        "SELECT full_name FROM users WHERE id = ?", (ticket_row["user_id"],)
    ).fetchone()
    messages = []
    if include_messages:
        msg_rows = conn.execute(
            "SELECT tm.*, u.full_name FROM ticket_messages tm JOIN users u ON u.id = tm.user_id WHERE ticket_id = ? ORDER BY tm.created_at",
            (ticket_row["id"],),
        ).fetchall()
        messages = [
            TicketMessageOut(
                id=m["id"],
                user_id=m["user_id"],
                user_name=m["full_name"],
                message=m["message"],
                is_admin=bool(m["is_admin"]),
                created_at=m["created_at"],
            )
            for m in msg_rows
        ]
    return TicketOut(
        id=ticket_row["id"],
        order_id=ticket_row["order_id"],
        order_number=order["order_number"] if order else "",
        user_id=ticket_row["user_id"],
        user_name=user["full_name"] if user else "",
        subject=ticket_row["subject"],
        status=ticket_row["status"],
        created_at=ticket_row["created_at"],
        updated_at=ticket_row["updated_at"],
        messages=messages,
    )


@router.post("", response_model=TicketOut)
def create_ticket(data: TicketCreate, user: dict = Depends(get_current_user)):
    conn = get_conn()
    order = conn.execute(
        "SELECT id, status FROM orders WHERE id = ? AND user_id = ?",
        (data.order_id, user["id"]),
    ).fetchone()
    if order is None:
        conn.close()
        raise HTTPException(status_code=404, detail="سفارش یافت نشد")
    if order["status"] in ("delivered", "cancelled"):
        conn.close()
        raise HTTPException(status_code=400, detail="فقط برای سفارش‌های در جریان می‌توانید تیکت ثبت کنید")

    now = datetime.now().isoformat()
    cur = conn.cursor()
    cur.execute(
        "INSERT INTO tickets (order_id, user_id, subject, status, created_at, updated_at) VALUES (?, ?, ?, 'open', ?, ?)",
        (data.order_id, user["id"], data.subject, now, now),
    )
    ticket_id = cur.lastrowid
    cur.execute(
        "INSERT INTO ticket_messages (ticket_id, user_id, message, is_admin, created_at) VALUES (?, ?, ?, 0, ?)",
        (ticket_id, user["id"], data.message, now),
    )
    conn.commit()
    ticket = conn.execute("SELECT * FROM tickets WHERE id = ?", (ticket_id,)).fetchone()
    result = _build_ticket(conn, ticket)
    conn.close()
    return result


@router.get("/my", response_model=list[TicketOut])
def my_tickets(user: dict = Depends(get_current_user)):
    conn = get_conn()
    rows = conn.execute(
        "SELECT * FROM tickets WHERE user_id = ? ORDER BY updated_at DESC",
        (user["id"],),
    ).fetchall()
    tickets = [_build_ticket(conn, r, include_messages=False) for r in rows]
    conn.close()
    return tickets


@router.get("/my/{ticket_id}", response_model=TicketOut)
def my_ticket_detail(ticket_id: int, user: dict = Depends(get_current_user)):
    conn = get_conn()
    row = conn.execute(
        "SELECT * FROM tickets WHERE id = ? AND user_id = ?",
        (ticket_id, user["id"]),
    ).fetchone()
    if row is None:
        conn.close()
        raise HTTPException(status_code=404, detail="تیکت یافت نشد")
    result = _build_ticket(conn, row)
    conn.close()
    return result


@router.post("/my/{ticket_id}/messages", response_model=TicketOut)
def add_user_message(ticket_id: int, data: TicketMessageCreate, user: dict = Depends(get_current_user)):
    conn = get_conn()
    row = conn.execute(
        "SELECT * FROM tickets WHERE id = ? AND user_id = ?",
        (ticket_id, user["id"]),
    ).fetchone()
    if row is None:
        conn.close()
        raise HTTPException(status_code=404, detail="تیکت یافت نشد")

    now = datetime.now().isoformat()
    conn.execute(
        "INSERT INTO ticket_messages (ticket_id, user_id, message, is_admin, created_at) VALUES (?, ?, ?, 0, ?)",
        (ticket_id, user["id"], data.message, now),
    )
    conn.execute(
        "UPDATE tickets SET status = 'open', updated_at = ? WHERE id = ?",
        (now, ticket_id),
    )
    conn.commit()
    row = conn.execute("SELECT * FROM tickets WHERE id = ?", (ticket_id,)).fetchone()
    result = _build_ticket(conn, row)
    conn.close()
    return result


@admin_router.get("", response_model=list[TicketOut])
def admin_list_tickets(status: str | None = None, _: dict = Depends(require_admin)):
    conn = get_conn()
    if status:
        rows = conn.execute(
            "SELECT * FROM tickets WHERE status = ? ORDER BY updated_at DESC", (status,)
        ).fetchall()
    else:
        rows = conn.execute("SELECT * FROM tickets ORDER BY updated_at DESC").fetchall()
    tickets = [_build_ticket(conn, r, include_messages=False) for r in rows]
    conn.close()
    return tickets


@admin_router.get("/{ticket_id}", response_model=TicketOut)
def admin_ticket_detail(ticket_id: int, _: dict = Depends(require_admin)):
    conn = get_conn()
    row = conn.execute("SELECT * FROM tickets WHERE id = ?", (ticket_id,)).fetchone()
    if row is None:
        conn.close()
        raise HTTPException(status_code=404, detail="تیکت یافت نشد")
    result = _build_ticket(conn, row)
    conn.close()
    return result


@admin_router.post("/{ticket_id}/messages", response_model=TicketOut)
def admin_reply(ticket_id: int, data: TicketMessageCreate, admin: dict = Depends(require_admin)):
    conn = get_conn()
    row = conn.execute("SELECT * FROM tickets WHERE id = ?", (ticket_id,)).fetchone()
    if row is None:
        conn.close()
        raise HTTPException(status_code=404, detail="تیکت یافت نشد")

    now = datetime.now().isoformat()
    conn.execute(
        "INSERT INTO ticket_messages (ticket_id, user_id, message, is_admin, created_at) VALUES (?, ?, ?, 1, ?)",
        (ticket_id, admin["id"], data.message, now),
    )
    conn.execute(
        "UPDATE tickets SET updated_at = ? WHERE id = ?",
        (now, ticket_id),
    )
    conn.commit()
    row = conn.execute("SELECT * FROM tickets WHERE id = ?", (ticket_id,)).fetchone()
    result = _build_ticket(conn, row)
    conn.close()
    return result


@admin_router.patch("/{ticket_id}/close", response_model=TicketOut)
def close_ticket(ticket_id: int, _: dict = Depends(require_admin)):
    conn = get_conn()
    row = conn.execute("SELECT * FROM tickets WHERE id = ?", (ticket_id,)).fetchone()
    if row is None:
        conn.close()
        raise HTTPException(status_code=404, detail="تیکت یافت نشد")
    now = datetime.now().isoformat()
    conn.execute(
        "UPDATE tickets SET status = 'closed', updated_at = ? WHERE id = ?",
        (now, ticket_id),
    )
    conn.commit()
    row = conn.execute("SELECT * FROM tickets WHERE id = ?", (ticket_id,)).fetchone()
    result = _build_ticket(conn, row)
    conn.close()
    return result
