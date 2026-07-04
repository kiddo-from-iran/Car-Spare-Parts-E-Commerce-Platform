from typing import Optional

from fastapi import APIRouter, HTTPException, Query

import catalog_db
from data.smart_catalog import (
    CATALOG_CATEGORIES,
    CATALOG_VEHICLES,
    get_hotspots as static_get_hotspots,
    get_vehicle as static_get_vehicle,
    search_hotspots as static_search_hotspots,
)
from database import get_conn, row_to_product
from models import CatalogCategory, CatalogHotspot, CatalogHotspotProduct, CatalogVehicle, CatalogVehicleSummary, Product

router = APIRouter(prefix="/api/smart-catalog", tags=["smart-catalog"])


def _use_db() -> bool:
    return catalog_db.has_db_catalog()


@router.get("/categories")
def list_categories():
    return CATALOG_CATEGORIES


def _static_list_vehicles(search: Optional[str] = None) -> list[dict]:
    items = CATALOG_VEHICLES
    if search:
        q = search.strip().lower()
        items = [v for v in items if q in v["name"].lower() or q in v.get("subtitle", "").lower()]
    return items


@router.get("/vehicles", response_model=list[CatalogVehicleSummary])
def list_vehicles(search: Optional[str] = Query(None)):
    if _use_db():
        items = catalog_db.list_vehicle_summaries(search)
    else:
        items = _static_list_vehicles(search)
    return [
        CatalogVehicleSummary(
            id=v["id"],
            name=v["name"],
            subtitle=v.get("subtitle", ""),
            year=v.get("year", ""),
            brand_logo=v.get("brand_logo", ""),
            image=v["image"],
        )
        for v in items
    ]


@router.get("/vehicles/{vehicle_id}", response_model=CatalogVehicle)
def get_vehicle_detail(vehicle_id: str):
    vehicle = catalog_db.get_vehicle(vehicle_id) if _use_db() else static_get_vehicle(vehicle_id)
    if vehicle is None:
        raise HTTPException(status_code=404, detail="خودرو یافت نشد")
    return CatalogVehicle(
        id=vehicle["id"],
        name=vehicle["name"],
        subtitle=vehicle.get("subtitle", ""),
        year=vehicle.get("year", ""),
        brand_logo=vehicle.get("brand_logo", ""),
        image=vehicle["image"],
        views=vehicle["views"],
        categories=vehicle.get("categories") or CATALOG_CATEGORIES,
    )


@router.get("/vehicles/{vehicle_id}/views/{view_id}/hotspots", response_model=list[CatalogHotspot])
def get_view_hotspots(vehicle_id: str, view_id: str, category: Optional[str] = None):
    vehicle = catalog_db.get_vehicle(vehicle_id) if _use_db() else static_get_vehicle(vehicle_id)
    if vehicle is None:
        raise HTTPException(status_code=404, detail="خودرو یافت نشد")
    if not any(v["id"] == view_id for v in vehicle["views"]):
        raise HTTPException(status_code=404, detail="نما یافت نشد")

    hotspots = (
        catalog_db.get_hotspots(vehicle_id, view_id, category)
        if _use_db()
        else static_get_hotspots(vehicle_id, view_id)
    )
    if category and not _use_db():
        hotspots = [h for h in hotspots if h["category"] == category]
    return [CatalogHotspot(**h) for h in hotspots]


@router.get("/vehicles/{vehicle_id}/search-hotspots")
def search_vehicle_hotspots(vehicle_id: str, q: str = Query(..., min_length=1)):
    vehicle = catalog_db.get_vehicle(vehicle_id) if _use_db() else static_get_vehicle(vehicle_id)
    if vehicle is None:
        raise HTTPException(status_code=404, detail="خودرو یافت نشد")
    return catalog_db.search_hotspots(vehicle_id, q) if _use_db() else static_search_hotspots(vehicle_id, q)


@router.get("/hotspots/{vehicle_id}/{hotspot_id}/product", response_model=CatalogHotspotProduct)
def get_hotspot_product(vehicle_id: str, hotspot_id: str, view_id: str = Query(...)):
    if _use_db():
        data = catalog_db.get_hotspot_with_products(vehicle_id, view_id, hotspot_id)
        if data is None:
            raise HTTPException(status_code=404, detail="قطعه یافت نشد")
        hotspot = data["hotspot"]
        products = [Product(**p) for p in data["products"]]
        if not products:
            raise HTTPException(status_code=404, detail="محصولی برای این نقطه تعریف نشده")
        primary = products[0]
        conn = get_conn()
        related = conn.execute(
            "SELECT * FROM products WHERE category = ? AND id != ? ORDER BY popularity DESC LIMIT 6",
            (primary.category, primary.id),
        ).fetchall()
        conn.close()
        return CatalogHotspotProduct(
            hotspot=CatalogHotspot(**hotspot),
            product=primary,
            products=products,
            part_number=hotspot.get("part_number", ""),
            oem_number=hotspot.get("oem", ""),
            material="",
            weight_grams=0,
            warranty="",
            related=[Product(**row_to_product(r)) for r in related],
        )

    hotspots = static_get_hotspots(vehicle_id, view_id)
    hotspot = next((h for h in hotspots if h["id"] == hotspot_id), None)
    if hotspot is None:
        raise HTTPException(status_code=404, detail="قطعه یافت نشد")

    conn = get_conn()
    row = conn.execute("SELECT * FROM products WHERE id = ?", (hotspot["product_id"],)).fetchone()
    if row is None:
        conn.close()
        raise HTTPException(status_code=404, detail="محصول یافت نشد")

    product = row_to_product(row)
    related = conn.execute(
        "SELECT * FROM products WHERE category = ? AND id != ? ORDER BY popularity DESC LIMIT 6",
        (product["category"], product["id"]),
    ).fetchall()
    conn.close()
    primary = Product(**product)
    return CatalogHotspotProduct(
        hotspot=CatalogHotspot(**{**hotspot, "product_ids": [hotspot.get("product_id", 0)]}),
        product=primary,
        products=[primary],
        part_number=hotspot.get("part_number", ""),
        oem_number=hotspot.get("oem", ""),
        material="پلاستیک / شیشه",
        weight_grams=1250,
        warranty="۶ ماه",
        related=[Product(**row_to_product(r)) for r in related],
    )
