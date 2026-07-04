def resolve_user_email(phone: str, email: str | None) -> str | None:
    if email and str(email).strip():
        return str(email).strip().lower()
    return None


def email_for_insert(phone: str, email: str | None) -> str | None:
    """Use explicit email when provided; otherwise NULL once schema allows it."""
    return resolve_user_email(phone, email)


def email_for_legacy_insert(phone: str, email: str | None) -> str:
    """Fallback for databases where users.email is still NOT NULL."""
    resolved = resolve_user_email(phone, email)
    if resolved:
        return resolved
    return f"{phone}@phone.montakhab"
