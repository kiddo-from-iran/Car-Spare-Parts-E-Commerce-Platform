import json
import os
from datetime import datetime, timedelta
from typing import Optional

import jwt
from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from database import get_conn, verify_password
from otp_utils import normalize_phone

SECRET_KEY = os.getenv("JWT_SECRET", "montakhab-dev-secret-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_HOURS = 72

security = HTTPBearer(auto_error=False)


def user_row_to_dict(row) -> dict:
    return {
        "id": row["id"],
        "phone": row["phone"] or "",
        "email": row["email"],
        "full_name": row["full_name"],
        "role": row["role"],
    }


def create_token(user_id: int, phone: str, role: str) -> str:
    payload = {
        "sub": str(user_id),
        "phone": phone,
        "role": role,
        "exp": datetime.utcnow() + timedelta(hours=ACCESS_TOKEN_EXPIRE_HOURS),
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def decode_token(token: str) -> dict:
    try:
        return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    except jwt.PyJWTError as exc:
        raise HTTPException(status_code=401, detail="توکن نامعتبر است") from exc


def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security),
) -> dict:
    if credentials is None:
        raise HTTPException(status_code=401, detail="لطفاً وارد شوید")
    payload = decode_token(credentials.credentials)
    conn = get_conn()
    row = conn.execute(
        "SELECT id, phone, email, full_name, role FROM users WHERE id = ?",
        (int(payload["sub"]),),
    ).fetchone()
    conn.close()
    if row is None:
        raise HTTPException(status_code=401, detail="کاربر یافت نشد")
    return user_row_to_dict(row)


def require_admin(user: dict = Depends(get_current_user)) -> dict:
    if user["role"] != "admin":
        raise HTTPException(status_code=403, detail="دسترسی مدیر لازم است")
    return user


def authenticate_user(phone: str, password: str) -> Optional[dict]:
    phone = normalize_phone(phone)
    conn = get_conn()
    row = conn.execute(
        "SELECT id, phone, email, password_hash, full_name, role FROM users WHERE phone = ?",
        (phone,),
    ).fetchone()
    conn.close()
    if row is None or not verify_password(password, row["password_hash"]):
        return None
    return user_row_to_dict(row)
