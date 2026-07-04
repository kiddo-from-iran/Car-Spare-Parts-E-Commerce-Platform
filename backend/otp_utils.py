import random
from datetime import datetime, timedelta

from database import get_conn


def generate_otp() -> str:
    return f"{random.randint(100000, 999999)}"


def store_otp(phone: str, purpose: str, payload: str = "", minutes: int = 5) -> str:
    code = generate_otp()
    expires = (datetime.now() + timedelta(minutes=minutes)).isoformat()
    conn = get_conn()
    conn.execute("DELETE FROM otp_codes WHERE phone = ? AND purpose = ?", (phone, purpose))
    conn.execute(
        "INSERT INTO otp_codes (phone, code, purpose, payload, expires_at, created_at) VALUES (?, ?, ?, ?, ?, ?)",
        (phone, code, purpose, payload, expires, datetime.now().isoformat()),
    )
    conn.commit()
    conn.close()
    print(f"[OTP] phone={phone} purpose={purpose} code={code}")
    return code


def verify_otp(phone: str, purpose: str, code: str) -> str | None:
    conn = get_conn()
    row = conn.execute(
        "SELECT code, payload, expires_at FROM otp_codes WHERE phone = ? AND purpose = ?",
        (phone, purpose),
    ).fetchone()
    if row is None:
        conn.close()
        return None
    if datetime.fromisoformat(row["expires_at"]) < datetime.now():
        conn.close()
        return None
    if row["code"] != code:
        conn.close()
        return None
    conn.execute("DELETE FROM otp_codes WHERE phone = ? AND purpose = ?", (phone, purpose))
    conn.commit()
    conn.close()
    return row["payload"] or ""


def normalize_phone(phone: str) -> str:
    p = phone.strip().replace(" ", "").replace("-", "")
    if p.startswith("+98"):
        p = "0" + p[3:]
    if p.startswith("98") and len(p) == 12:
        p = "0" + p[2:]
    return p
