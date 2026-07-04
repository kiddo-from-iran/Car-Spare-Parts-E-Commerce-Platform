import json
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query

from auth_utils import require_admin
from constants import (
    BRANDS_LIST,
    CATEGORIES,
    FOOTER_CATEGORIES,
    MANUFACTURER_COUNTRIES_LIST,
    ORDER_STATUS_LABELS,
    OrderStatus,
)
from data.categories import MEGA_MENU, PART_CATEGORIES, PARTNER_BRANDS, VEHICLE_CATEGORIES
from database import get_conn, row_to_product
from models import PartnerBrand, Product, ProductCreate, ProductUpdate, SearchSuggestion


def _sort_products(products: list[dict], sort: Optional[str]) -> list[dict]:
    if sort == "price_asc":
        return sorted(products, key=lambda p: p["price"])
    if sort == "price_desc":
        return sorted(products, key=lambda p: p["price"], reverse=True)
    if sort == "newest":
        return sorted(products, key=lambda p: p["created_at"], reverse=True)
    if sort == "popularity":
        return sorted(products, key=lambda p: p["popularity"], reverse=True)
    if sort == "views":
        return sorted(products, key=lambda p: p.get("views", 0), reverse=True)
    if sort == "discount":
        return sorted(products, key=lambda p: p.get("discount_percent", 0), reverse=True)
    return products


def _filter_products(
    results: list[dict],
    *,
    category: Optional[str] = None,
    part_category: Optional[str] = None,
    vehicle: Optional[str] = None,
    brand: Optional[str] = None,
    country: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    color: Optional[str] = None,
    search: Optional[str] = None,
    in_stock_only: Optional[bool] = None,
    out_of_stock_only: Optional[bool] = None,
    has_discount: Optional[bool] = None,
) -> list[dict]:
    if category:
        results = [p for p in results if p["category"] == category or p.get("part_category") == category]
    if part_category:
        results = [p for p in results if p.get("part_category") == part_category]
    if vehicle:
        results = [p for p in results if vehicle in p.get("compatible_vehicles", [])]
    if brand:
        results = [p for p in results if p.get("brand") == brand]
    if country:
        results = [p for p in results if p.get("manufacturer_country") == country]
    if min_price is not None:
        results = [p for p in results if p["price"] >= min_price]
    if max_price is not None:
        results = [p for p in results if p["price"] <= max_price]
    if color:
        results = [p for p in results if any(c == color for c in p["colors"])]
    if search:
        q = search.lower()
        results = [
            p for p in results
            if q in p["name"].lower()
            or q in p["description"].lower()
            or q in p.get("brand", "").lower()
        ]
    if in_stock_only:
        results = [p for p in results if p["in_stock"]]
    if out_of_stock_only:
        results = [p for p in results if not p["in_stock"]]
    if has_discount:
        results = [p for p in results if p.get("discount_percent", 0) > 0]
    return results


products_router = APIRouter(prefix="/api", tags=["products"])


@products_router.get("/health")
def health():
    return {"status": "ok", "store": "جهانگیری"}


@products_router.get("/categories")
def get_categories():
    return CATEGORIES


@products_router.get("/footer-categories")
def get_footer_categories():
    return FOOTER_CATEGORIES


@products_router.get("/mega-menu")
def get_mega_menu():
    return MEGA_MENU


@products_router.get("/vehicle-categories")
def get_vehicle_categories():
    return VEHICLE_CATEGORIES


@products_router.get("/part-categories")
def get_part_categories():
    return PART_CATEGORIES


@products_router.get("/brands")
def get_brands():
    return BRANDS_LIST


@products_router.get("/manufacturer-countries")
def get_manufacturer_countries():
    return MANUFACTURER_COUNTRIES_LIST


@products_router.get("/partner-brands", response_model=list[PartnerBrand])
def get_partner_brands():
    return PARTNER_BRANDS


@products_router.get("/search/suggest", response_model=list[SearchSuggestion])
def search_suggest(
    q: str = Query(..., min_length=2),
    limit: int = Query(8, ge=1, le=20),
):
    pattern = f"%{q.strip()}%"
    conn = get_conn()
    rows = conn.execute(
        """
        SELECT id, name, price, brand, category, part_category, images, popularity
        FROM products
        WHERE name LIKE ? OR brand LIKE ? OR description LIKE ?
           OR part_category LIKE ?
        ORDER BY popularity DESC, name ASC
        LIMIT ?
        """,
        (pattern, pattern, pattern, pattern, limit),
    ).fetchall()
    conn.close()

    results: list[SearchSuggestion] = []
    for row in rows:
        images = json.loads(row["images"])
        category = row["part_category"] or row["category"]
        results.append(
            SearchSuggestion(
                id=row["id"],
                name=row["name"],
                price=row["price"],
                brand=row["brand"] or "",
                category=category or "",
                image=images[0] if images else "",
            )
        )
    return results


@products_router.get("/products", response_model=list[Product])
def list_products(
    category: Optional[str] = None,
    part_category: Optional[str] = None,
    vehicle: Optional[str] = None,
    brand: Optional[str] = None,
    country: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    color: Optional[str] = None,
    search: Optional[str] = None,
    sort: Optional[str] = Query(None),
    featured: Optional[bool] = None,
    in_stock_only: Optional[bool] = None,
    out_of_stock_only: Optional[bool] = None,
    has_discount: Optional[bool] = None,
    page: Optional[int] = Query(None, ge=1),
    page_size: Optional[int] = Query(None, ge=1, le=100),
):
    conn = get_conn()
    rows = conn.execute("SELECT * FROM products").fetchall()
    conn.close()
    results = [row_to_product(r) for r in rows]

    results = _filter_products(
        results,
        category=category,
        part_category=part_category,
        vehicle=vehicle,
        brand=brand,
        country=country,
        min_price=min_price,
        max_price=max_price,
        color=color,
        search=search,
        in_stock_only=in_stock_only,
        out_of_stock_only=out_of_stock_only,
        has_discount=has_discount,
    )

    if featured:
        results = sorted(results, key=lambda p: p["popularity"], reverse=True)[:8]

    results = _sort_products(results, sort)

    if page is not None and page_size is not None:
        start = (page - 1) * page_size
        results = results[start : start + page_size]

    return results


@products_router.get("/products/count")
def count_products(
    category: Optional[str] = None,
    part_category: Optional[str] = None,
    vehicle: Optional[str] = None,
    brand: Optional[str] = None,
    country: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    search: Optional[str] = None,
    in_stock_only: Optional[bool] = None,
    out_of_stock_only: Optional[bool] = None,
    has_discount: Optional[bool] = None,
):
    conn = get_conn()
    rows = conn.execute("SELECT * FROM products").fetchall()
    conn.close()
    results = _filter_products(
        [row_to_product(r) for r in rows],
        category=category,
        part_category=part_category,
        vehicle=vehicle,
        brand=brand,
        country=country,
        min_price=min_price,
        max_price=max_price,
        search=search,
        in_stock_only=in_stock_only,
        out_of_stock_only=out_of_stock_only,
        has_discount=has_discount,
    )
    return {"count": len(results)}


@products_router.get("/products/{product_id}", response_model=Product)
def get_product(product_id: int):
    conn = get_conn()
    row = conn.execute("SELECT * FROM products WHERE id = ?", (product_id,)).fetchone()
    if row is None:
        conn.close()
        raise HTTPException(status_code=404, detail="محصول یافت نشد")
    conn.execute("UPDATE products SET views = views + 1 WHERE id = ?", (product_id,))
    conn.commit()
    row = conn.execute("SELECT * FROM products WHERE id = ?", (product_id,)).fetchone()
    conn.close()
    return row_to_product(row)


@products_router.get("/products/{product_id}/related", response_model=list[Product])
def get_related(product_id: int, limit: int = 4):
    conn = get_conn()
    product = conn.execute("SELECT * FROM products WHERE id = ?", (product_id,)).fetchone()
    if product is None:
        conn.close()
        raise HTTPException(status_code=404, detail="محصول یافت نشد")
    rows = conn.execute(
        "SELECT * FROM products WHERE category = ? AND id != ? ORDER BY popularity DESC LIMIT ?",
        (product["category"], product_id, limit),
    ).fetchall()
    conn.close()
    return [row_to_product(r) for r in rows]


@products_router.get("/colors")
def get_colors():
    conn = get_conn()
    rows = conn.execute("SELECT colors FROM products").fetchall()
    conn.close()
    colors: set[str] = set()
    for row in rows:
        colors.update(json.loads(row["colors"]))
    return sorted(colors)


@products_router.get("/order-statuses")
def order_statuses():
    return [{"value": s.value, "label": ORDER_STATUS_LABELS[s]} for s in OrderStatus]


def _product_insert_values(data: ProductCreate | dict, now: str | None = None) -> tuple:
    if isinstance(data, ProductCreate):
        d = data.model_dump()
    else:
        d = data
    return (
        d["name"],
        d["price"],
        d.get("original_price", d["price"]),
        d.get("discount_percent", 0),
        d["description"],
        d["category"],
        d.get("part_category", d["category"]),
        d.get("brand", ""),
        d.get("manufacturer_country", ""),
        json.dumps(d.get("compatible_vehicles", []), ensure_ascii=False),
        json.dumps(d.get("colors", []), ensure_ascii=False),
        json.dumps(d.get("sizes", ["استاندارد"]), ensure_ascii=False),
        json.dumps(d.get("images", []), ensure_ascii=False),
        json.dumps(d.get("specs", {}), ensure_ascii=False),
        d.get("popularity", 0),
        d.get("views", 0),
        d.get("rating", 0),
        d.get("review_count", 0),
        d.get("stock_quantity", 0),
        int(d.get("is_new", False)),
        int(d.get("in_stock", True)),
        now or datetime.now().isoformat(),
    )


admin_products_router = APIRouter(prefix="/api/admin/products", tags=["admin-products"])


@admin_products_router.get("", response_model=list[Product])
def admin_list_products(_: dict = Depends(require_admin)):
    conn = get_conn()
    rows = conn.execute("SELECT * FROM products ORDER BY id DESC").fetchall()
    conn.close()
    return [row_to_product(r) for r in rows]


@admin_products_router.post("", response_model=Product)
def create_product(data: ProductCreate, _: dict = Depends(require_admin)):
    conn = get_conn()
    now = datetime.now().isoformat()
    cur = conn.cursor()
    cur.execute(
        """INSERT INTO products
        (name, price, original_price, discount_percent, description, category, part_category,
         brand, manufacturer_country, compatible_vehicles, colors, sizes, images, specs,
         popularity, views, rating, review_count, stock_quantity, is_new, in_stock, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        _product_insert_values(data, now),
    )
    product_id = cur.lastrowid
    conn.commit()
    row = conn.execute("SELECT * FROM products WHERE id = ?", (product_id,)).fetchone()
    conn.close()
    return row_to_product(row)


@admin_products_router.put("/{product_id}", response_model=Product)
def update_product(product_id: int, data: ProductUpdate, _: dict = Depends(require_admin)):
    conn = get_conn()
    row = conn.execute("SELECT * FROM products WHERE id = ?", (product_id,)).fetchone()
    if row is None:
        conn.close()
        raise HTTPException(status_code=404, detail="محصول یافت نشد")

    current = row_to_product(row)
    updates = {k: v for k, v in data.model_dump(exclude_unset=True).items()}
    merged = {**current, **updates}
    conn.execute(
        """UPDATE products SET name=?, price=?, original_price=?, discount_percent=?, description=?,
        category=?, part_category=?, brand=?, manufacturer_country=?, compatible_vehicles=?,
        colors=?, sizes=?, images=?, specs=?, popularity=?, views=?, rating=?, review_count=?,
        stock_quantity=?, is_new=?, in_stock=? WHERE id=?""",
        (
            merged["name"],
            merged["price"],
            merged.get("original_price", merged["price"]),
            merged.get("discount_percent", 0),
            merged["description"],
            merged["category"],
            merged.get("part_category", merged["category"]),
            merged.get("brand", ""),
            merged.get("manufacturer_country", ""),
            json.dumps(merged.get("compatible_vehicles", []), ensure_ascii=False),
            json.dumps(merged["colors"], ensure_ascii=False),
            json.dumps(merged["sizes"], ensure_ascii=False),
            json.dumps(merged["images"], ensure_ascii=False),
            json.dumps(merged.get("specs", {}), ensure_ascii=False),
            merged["popularity"],
            merged.get("views", 0),
            merged.get("rating", 0),
            merged.get("review_count", 0),
            merged.get("stock_quantity", 0),
            int(merged["is_new"]),
            int(merged["in_stock"]),
            product_id,
        ),
    )
    conn.commit()
    row = conn.execute("SELECT * FROM products WHERE id = ?", (product_id,)).fetchone()
    conn.close()
    return row_to_product(row)


@admin_products_router.delete("/{product_id}")
def delete_product(product_id: int, _: dict = Depends(require_admin)):
    conn = get_conn()
    row = conn.execute("SELECT id FROM products WHERE id = ?", (product_id,)).fetchone()
    if row is None:
        conn.close()
        raise HTTPException(status_code=404, detail="محصول یافت نشد")
    conn.execute("DELETE FROM products WHERE id = ?", (product_id,))
    conn.commit()
    conn.close()
    return {"message": "محصول حذف شد"}


@admin_products_router.post("/{product_id}/duplicate", response_model=Product)
def duplicate_product(product_id: int, _: dict = Depends(require_admin)):
    conn = get_conn()
    row = conn.execute("SELECT * FROM products WHERE id = ?", (product_id,)).fetchone()
    if row is None:
        conn.close()
        raise HTTPException(status_code=404, detail="محصول یافت نشد")
    product = row_to_product(row)
    product["name"] = f"{product['name']} (کپی)"
    now = datetime.now().isoformat()
    cur = conn.cursor()
    cur.execute(
        """INSERT INTO products
        (name, price, original_price, discount_percent, description, category, part_category,
         brand, manufacturer_country, compatible_vehicles, colors, sizes, images, specs,
         popularity, views, rating, review_count, stock_quantity, is_new, in_stock, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        _product_insert_values(product, now),
    )
    new_id = cur.lastrowid
    conn.commit()
    row = conn.execute("SELECT * FROM products WHERE id = ?", (new_id,)).fetchone()
    conn.close()
    return row_to_product(row)
