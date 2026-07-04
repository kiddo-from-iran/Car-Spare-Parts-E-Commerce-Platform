import uuid
from pathlib import Path

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile

from auth_utils import require_admin
from catalog_db import (
    admin_delete_catalog,
    admin_get_catalog,
    admin_list_catalogs,
    admin_save_catalog,
)
from models import AdminCatalogSave, AdminCatalogSummary

router = APIRouter(prefix="/api/admin/catalogs", tags=["admin-catalogs"])

UPLOAD_DIR = Path(__file__).parent.parent / "static" / "catalog"
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)


@router.get("", response_model=list[AdminCatalogSummary])
def list_catalogs(_: dict = Depends(require_admin)):
    rows = admin_list_catalogs()
    return [
        AdminCatalogSummary(
            id=r["id"],
            name=r["name"],
            subtitle=r.get("subtitle") or "",
            year=r.get("year") or "",
            brand_logo=r.get("brand_logo") or "",
            image=r.get("image") or "",
            view_count=int(r.get("view_count") or 0),
            hotspot_count=int(r.get("hotspot_count") or 0),
            created_at=r.get("created_at") or "",
            updated_at=r.get("updated_at") or "",
        )
        for r in rows
    ]


@router.get("/{vehicle_id}")
def get_catalog(vehicle_id: str, _: dict = Depends(require_admin)):
    data = admin_get_catalog(vehicle_id)
    if data is None:
        raise HTTPException(status_code=404, detail="کاتالوگ یافت نشد")
    return data


@router.post("", response_model=dict)
def create_catalog(data: AdminCatalogSave, _: dict = Depends(require_admin)):
    return admin_save_catalog(data.model_dump())


@router.put("/{vehicle_id}", response_model=dict)
def update_catalog(vehicle_id: str, data: AdminCatalogSave, _: dict = Depends(require_admin)):
    payload = data.model_dump()
    payload["id"] = vehicle_id
    return admin_save_catalog(payload)


@router.delete("/{vehicle_id}")
def delete_catalog(vehicle_id: str, _: dict = Depends(require_admin)):
    if not admin_delete_catalog(vehicle_id):
        raise HTTPException(status_code=404, detail="کاتالوگ یافت نشد")
    return {"ok": True}


@router.post("/upload-image")
async def upload_catalog_image(
    file: UploadFile = File(...),
    _: dict = Depends(require_admin),
):
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="فقط فایل تصویر مجاز است")

    ext = Path(file.filename or "image.png").suffix.lower() or ".png"
    if ext not in {".png", ".jpg", ".jpeg", ".webp", ".gif"}:
        ext = ".png"

    name = f"{uuid.uuid4().hex}{ext}"
    dest = UPLOAD_DIR / name
    content = await file.read()
    dest.write_bytes(content)

    return {"url": f"/static/catalog/{name}"}
