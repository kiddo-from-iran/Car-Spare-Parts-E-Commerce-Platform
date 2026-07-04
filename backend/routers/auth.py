import json
import sqlite3
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException

from auth_email import email_for_insert, email_for_legacy_insert
from auth_utils import authenticate_user, create_token, get_current_user, user_row_to_dict
from database import get_conn, hash_password
from models import (
    AddressCreate,
    AddressOut,
    AddressUpdate,
    ForgotPasswordSendOtpRequest,
    LoginRequest,
    OtpSentResponse,
    ProfileUpdateRequest,
    RegisterSendOtpRequest,
    ResetPasswordRequest,
    TokenResponse,
    UserPublic,
    VerifyOtpRequest,
)
from otp_utils import normalize_phone, store_otp, verify_otp

router = APIRouter(prefix="/api/auth", tags=["auth"])


def _address_row(row) -> AddressOut:
    return AddressOut(
        id=row["id"],
        label=row["label"],
        first_name=row["first_name"],
        last_name=row["last_name"],
        address=row["address"],
        city=row["city"],
        state=row["state"],
        zip_code=row["zip_code"],
        country=row["country"],
        is_default=bool(row["is_default"]),
    )


@router.post("/register/send-otp", response_model=OtpSentResponse)
def register_send_otp(data: RegisterSendOtpRequest):
    phone = normalize_phone(data.phone)
    if not phone.startswith("09") or len(phone) != 11:
        raise HTTPException(status_code=400, detail="شماره موبایل نامعتبر است")

    conn = get_conn()
    existing = conn.execute("SELECT id FROM users WHERE phone = ?", (phone,)).fetchone()
    conn.close()
    if existing:
        raise HTTPException(status_code=400, detail="این شماره قبلاً ثبت شده است")

    payload = json.dumps(
        {
            "password": data.password,
            "full_name": data.full_name,
            "email": data.email,
        },
        ensure_ascii=False,
    )
    code = store_otp(phone, "register", payload)
    return OtpSentResponse(
        message="کد تأیید ارسال شد (در کنسول مرورگر)",
        phone=phone,
        dev_otp=code,
    )


@router.post("/register/verify", response_model=TokenResponse)
def register_verify(data: VerifyOtpRequest):
    phone = normalize_phone(data.phone)
    payload = verify_otp(phone, "register", data.code)
    if payload is None:
        raise HTTPException(status_code=400, detail="کد تأیید نامعتبر یا منقضی شده است")

    info = json.loads(payload)
    now = datetime.now().isoformat()
    password_hash = hash_password(info["password"])
    email = email_for_insert(phone, info.get("email"))
    legacy_email = email_for_legacy_insert(phone, info.get("email"))
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute(
            """INSERT INTO users (phone, email, password_hash, full_name, role, phone_verified, created_at)
            VALUES (?, ?, ?, ?, 'user', 1, ?)""",
            (
                phone,
                email,
                password_hash,
                info["full_name"],
                now,
            ),
        )
    except sqlite3.IntegrityError as exc:
        if "NOT NULL constraint failed: users.email" in str(exc):
            cur.execute(
                """INSERT INTO users (phone, email, password_hash, full_name, role, phone_verified, created_at)
                VALUES (?, ?, ?, ?, 'user', 1, ?)""",
                (
                    phone,
                    legacy_email,
                    password_hash,
                    info["full_name"],
                    now,
                ),
            )
        elif "UNIQUE" in str(exc):
            conn.close()
            raise HTTPException(status_code=400, detail="این شماره یا ایمیل قبلاً ثبت شده است") from exc
        else:
            conn.close()
            raise HTTPException(status_code=400, detail="خطا در ثبت کاربر") from exc
    user_id = cur.lastrowid
    conn.commit()
    row = conn.execute(
        "SELECT id, phone, email, full_name, role FROM users WHERE id = ?", (user_id,)
    ).fetchone()
    conn.close()

    user = user_row_to_dict(row)
    token = create_token(user_id, phone, "user")
    return TokenResponse(access_token=token, user=UserPublic(**user))


@router.post("/login", response_model=TokenResponse)
def login(data: LoginRequest):
    user = authenticate_user(data.phone, data.password)
    if user is None:
        raise HTTPException(status_code=401, detail="شماره موبایل یا رمز عبور اشتباه است")
    token = create_token(user["id"], user["phone"], user["role"])
    return TokenResponse(access_token=token, user=UserPublic(**user))


@router.post("/forgot-password/send-otp", response_model=OtpSentResponse)
def forgot_password_send_otp(data: ForgotPasswordSendOtpRequest):
    phone = normalize_phone(data.phone)
    conn = get_conn()
    row = conn.execute("SELECT id FROM users WHERE phone = ?", (phone,)).fetchone()
    conn.close()
    if row is None:
        raise HTTPException(status_code=404, detail="کاربری با این شماره یافت نشد")
    code = store_otp(phone, "reset", "")
    return OtpSentResponse(
        message="کد بازیابی ارسال شد (در کنسول مرورگر)",
        phone=phone,
        dev_otp=code,
    )


@router.post("/forgot-password/reset", response_model=OtpSentResponse)
def forgot_password_reset(data: ResetPasswordRequest):
    phone = normalize_phone(data.phone)
    if verify_otp(phone, "reset", data.code) is None:
        raise HTTPException(status_code=400, detail="کد تأیید نامعتبر یا منقضی شده است")

    conn = get_conn()
    row = conn.execute("SELECT id FROM users WHERE phone = ?", (phone,)).fetchone()
    if row is None:
        conn.close()
        raise HTTPException(status_code=404, detail="کاربر یافت نشد")
    conn.execute(
        "UPDATE users SET password_hash = ? WHERE phone = ?",
        (hash_password(data.new_password), phone),
    )
    conn.commit()
    conn.close()
    return OtpSentResponse(message="رمز عبور با موفقیت تغییر کرد", phone=phone)


@router.get("/me", response_model=UserPublic)
def me(user: dict = Depends(get_current_user)):
    return UserPublic(**user)


@router.put("/profile", response_model=UserPublic)
def update_profile(data: ProfileUpdateRequest, user: dict = Depends(get_current_user)):
    conn = get_conn()
    row = conn.execute("SELECT * FROM users WHERE id = ?", (user["id"],)).fetchone()
    full_name = data.full_name if data.full_name is not None else row["full_name"]
    email = data.email if data.email is not None else row["email"]
    conn.execute(
        "UPDATE users SET full_name = ?, email = ? WHERE id = ?",
        (full_name, email, user["id"]),
    )
    conn.commit()
    updated = conn.execute(
        "SELECT id, phone, email, full_name, role FROM users WHERE id = ?", (user["id"],)
    ).fetchone()
    conn.close()
    return UserPublic(**user_row_to_dict(updated))


@router.get("/addresses", response_model=list[AddressOut])
def list_addresses(user: dict = Depends(get_current_user)):
    conn = get_conn()
    rows = conn.execute(
        "SELECT * FROM user_addresses WHERE user_id = ? ORDER BY is_default DESC, id DESC",
        (user["id"],),
    ).fetchall()
    conn.close()
    return [_address_row(r) for r in rows]


@router.post("/addresses", response_model=AddressOut)
def create_address(data: AddressCreate, user: dict = Depends(get_current_user)):
    conn = get_conn()
    now = datetime.now().isoformat()
    if data.is_default:
        conn.execute("UPDATE user_addresses SET is_default = 0 WHERE user_id = ?", (user["id"],))
    cur = conn.cursor()
    cur.execute(
        """INSERT INTO user_addresses
        (user_id, label, first_name, last_name, address, city, state, zip_code, country, is_default, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (
            user["id"],
            data.label,
            data.first_name,
            data.last_name,
            data.address,
            data.city,
            data.state,
            data.zip_code,
            data.country,
            int(data.is_default),
            now,
        ),
    )
    addr_id = cur.lastrowid
    conn.commit()
    row = conn.execute("SELECT * FROM user_addresses WHERE id = ?", (addr_id,)).fetchone()
    conn.close()
    return _address_row(row)


@router.put("/addresses/{address_id}", response_model=AddressOut)
def update_address(address_id: int, data: AddressUpdate, user: dict = Depends(get_current_user)):
    conn = get_conn()
    row = conn.execute(
        "SELECT * FROM user_addresses WHERE id = ? AND user_id = ?",
        (address_id, user["id"]),
    ).fetchone()
    if row is None:
        conn.close()
        raise HTTPException(status_code=404, detail="آدرس یافت نشد")

    if data.is_default:
        conn.execute("UPDATE user_addresses SET is_default = 0 WHERE user_id = ?", (user["id"],))

    conn.execute(
        """UPDATE user_addresses SET
        label=?, first_name=?, last_name=?, address=?, city=?, state=?, zip_code=?, country=?, is_default=?
        WHERE id=?""",
        (
            data.label if data.label is not None else row["label"],
            data.first_name if data.first_name is not None else row["first_name"],
            data.last_name if data.last_name is not None else row["last_name"],
            data.address if data.address is not None else row["address"],
            data.city if data.city is not None else row["city"],
            data.state if data.state is not None else row["state"],
            data.zip_code if data.zip_code is not None else row["zip_code"],
            data.country if data.country is not None else row["country"],
            int(data.is_default if data.is_default is not None else row["is_default"]),
            address_id,
        ),
    )
    conn.commit()
    updated = conn.execute("SELECT * FROM user_addresses WHERE id = ?", (address_id,)).fetchone()
    conn.close()
    return _address_row(updated)


@router.delete("/addresses/{address_id}")
def delete_address(address_id: int, user: dict = Depends(get_current_user)):
    conn = get_conn()
    row = conn.execute(
        "SELECT id FROM user_addresses WHERE id = ? AND user_id = ?",
        (address_id, user["id"]),
    ).fetchone()
    if row is None:
        conn.close()
        raise HTTPException(status_code=404, detail="آدرس یافت نشد")
    conn.execute("DELETE FROM user_addresses WHERE id = ?", (address_id,))
    conn.commit()
    conn.close()
    return {"message": "آدرس حذف شد"}
