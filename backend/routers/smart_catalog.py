from typing import Optional

from fastapi import APIRouter, HTTPException, Query

from data.smart_catalog import (
    CATALOG_CATEGORIES,
    CATALOG_VEHICLES,
    get_hotspots,
    get_vehicle,
    search_hotspots,
)
from database import get_conn, row_to_product
from models import CatalogHotspot, CatalogHotspotProduct, CatalogVehicle, CatalogVehicleSummary, Product


router = APIRouter(prefix="/api/smart-catalog", tags=["smart-catalog"])


@router.get("/categories")
def list_categories():
    return CATALOG_CATEGORIES


@router.get("/vehicles", response_model=list[CatalogVehicleSummary])
def list_vehicles(search: Optional[str] = Query(None)):
    items = CATALOG_VEHICLES
    if search:
        q = search.strip().lower()
        items = [v for v in items if q in v["name"].lower() or q in v.get("subtitle", "").lower()]
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
    vehicle = get_vehicle(vehicle_id)
    if vehicle is None:
        raise HTTPException(status_code=404, detail="خودرو یافت نشد")
    return CatalogVehicle(**vehicle, categories=CATALOG_CATEGORIES)


@router.get("/vehicles/{vehicle_id}/views/{view_id}/hotspots", response_model=list[CatalogHotspot])
def get_view_hotspots(vehicle_id: str, view_id: str, category: Optional[str] = None):
    vehicle = get_vehicle(vehicle_id)
    if vehicle is None:
        raise HTTPException(status_code=404, detail="خودرو یافت نشد")
    if not any(v["id"] == view_id for v in vehicle["views"]):
        raise HTTPException(status_code=404, detail="نما یافت نشد")
    hotspots = get_hotspots(vehicle_id, view_id)
    if category:
        hotspots = [h for h in hotspots if h["category"] == category]
    return [CatalogHotspot(**h) for h in hotspots]


@router.get("/vehicles/{vehicle_id}/search-hotspots")
def search_vehicle_hotspots(vehicle_id: str, q: str = Query(..., min_length=1)):
    vehicle = get_vehicle(vehicle_id)
    if vehicle is None:
        raise HTTPException(status_code=404, detail="خودرو یافت نشد")
    return search_hotspots(vehicle_id, q)


@router.get("/hotspots/{vehicle_id}/{hotspot_id}/product", response_model=CatalogHotspotProduct)
def get_hotspot_product(vehicle_id: str, hotspot_id: str, view_id: str = Query(...)):
    hotspots = get_hotspots(vehicle_id, view_id)
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

    return CatalogHotspotProduct(
        hotspot=CatalogHotspot(**hotspot),
        product=Product(**product),
        part_number=hotspot.get("part_number", ""),
        oem_number=hotspot.get("oem", ""),
        material="پلاستیک / شیشه",
        weight_grams=1250,
        warranty="۶ ماه",
        related=[Product(**row_to_product(r)) for r in related],
    )
