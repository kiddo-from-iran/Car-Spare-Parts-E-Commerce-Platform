"""Database-backed smart catalog (vehicles, views, hotspots, product links)."""

from __future__ import annotations

import json
import uuid
from datetime import datetime
from typing import Any, Optional

from data.smart_catalog import CATALOG_CATEGORIES, CATALOG_VEHICLES, get_hotspots as static_hotspots
from database import get_conn, row_to_product


def _now() -> str:
    return datetime.now().isoformat()


def _parse_vehicle_categories(raw: Any) -> list[dict]:
    if not raw:
        return list(CATALOG_CATEGORIES)
    try:
        parsed = json.loads(raw) if isinstance(raw, str) else raw
    except (TypeError, json.JSONDecodeError):
        return list(CATALOG_CATEGORIES)
    if not isinstance(parsed, list) or not parsed:
        return list(CATALOG_CATEGORIES)
    return [
        {
            "id": str(item.get("id") or ""),
            "name": str(item.get("name") or ""),
            "icon": str(item.get("icon") or "category"),
        }
        for item in parsed
        if item.get("id") and item.get("name")
    ] or list(CATALOG_CATEGORIES)


def _serialize_categories(categories: list[dict]) -> str:
    payload = [
        {
            "id": c.get("id", ""),
            "name": c.get("name", ""),
            "icon": c.get("icon", "category"),
        }
        for c in categories
        if c.get("id") and c.get("name")
    ]
    return json.dumps(payload, ensure_ascii=False)


def _table_exists(cur, name: str) -> bool:
    row = cur.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        (name,),
    ).fetchone()
    return row is not None


def ensure_catalog_tables(cur) -> None:
    cur.executescript(
        """
        CREATE TABLE IF NOT EXISTS catalog_vehicles (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            subtitle TEXT NOT NULL DEFAULT '',
            year TEXT NOT NULL DEFAULT '',
            brand_logo TEXT NOT NULL DEFAULT '',
            image TEXT NOT NULL DEFAULT '',
            categories_json TEXT NOT NULL DEFAULT '',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS catalog_views (
            vehicle_id TEXT NOT NULL,
            view_id TEXT NOT NULL,
            name TEXT NOT NULL,
            image TEXT NOT NULL DEFAULT '',
            sort_order INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY (vehicle_id, view_id),
            FOREIGN KEY (vehicle_id) REFERENCES catalog_vehicles(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS catalog_hotspots (
            vehicle_id TEXT NOT NULL,
            view_id TEXT NOT NULL,
            id TEXT NOT NULL,
            label TEXT NOT NULL,
            category TEXT NOT NULL DEFAULT 'body',
            x REAL NOT NULL,
            y REAL NOT NULL,
            part_number TEXT NOT NULL DEFAULT '',
            oem TEXT NOT NULL DEFAULT '',
            PRIMARY KEY (vehicle_id, view_id, id),
            FOREIGN KEY (vehicle_id, view_id) REFERENCES catalog_views(vehicle_id, view_id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS catalog_hotspot_products (
            vehicle_id TEXT NOT NULL,
            view_id TEXT NOT NULL,
            hotspot_id TEXT NOT NULL,
            product_id INTEGER NOT NULL,
            sort_order INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY (vehicle_id, view_id, hotspot_id, product_id),
            FOREIGN KEY (vehicle_id, view_id, hotspot_id)
                REFERENCES catalog_hotspots(vehicle_id, view_id, id) ON DELETE CASCADE,
            FOREIGN KEY (product_id) REFERENCES products(id)
        );
        """
    )


def seed_catalog_from_static(cur) -> None:
    if not _table_exists(cur, "catalog_vehicles"):
        return
    count = cur.execute("SELECT COUNT(*) FROM catalog_vehicles").fetchone()[0]
    if count > 0:
        return

    now = _now()
    for vehicle in CATALOG_VEHICLES:
        cur.execute(
            """INSERT INTO catalog_vehicles
            (id, name, subtitle, year, brand_logo, image, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                vehicle["id"],
                vehicle["name"],
                vehicle.get("subtitle", ""),
                vehicle.get("year", ""),
                vehicle.get("brand_logo", ""),
                vehicle["image"],
                now,
                now,
            ),
        )
        for sort_order, view in enumerate(vehicle.get("views", [])):
            cur.execute(
                """INSERT INTO catalog_views (vehicle_id, view_id, name, image, sort_order)
                VALUES (?, ?, ?, ?, ?)""",
                (vehicle["id"], view["id"], view["name"], view.get("image", ""), sort_order),
            )
            hotspots = static_hotspots(vehicle["id"], view["id"])
            for h in hotspots:
                cur.execute(
                    """INSERT INTO catalog_hotspots
                    (vehicle_id, view_id, id, label, category, x, y, part_number, oem)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                    (
                        vehicle["id"],
                        view["id"],
                        h["id"],
                        h["label"],
                        h.get("category", "body"),
                        h["x"],
                        h["y"],
                        h.get("part_number", ""),
                        h.get("oem", ""),
                    ),
                )
                product_id = h.get("product_id")
                if product_id:
                    cur.execute(
                        """INSERT INTO catalog_hotspot_products
                        (vehicle_id, view_id, hotspot_id, product_id, sort_order)
                        VALUES (?, ?, ?, ?, 0)""",
                        (vehicle["id"], view["id"], h["id"], product_id),
                    )


def has_db_catalog() -> bool:
    conn = get_conn()
    try:
        if not _table_exists(conn, "catalog_vehicles"):
            return False
        count = conn.execute("SELECT COUNT(*) FROM catalog_vehicles").fetchone()[0]
        return count > 0
    finally:
        conn.close()


def list_vehicle_summaries(search: Optional[str] = None) -> list[dict]:
    conn = get_conn()
    rows = conn.execute("SELECT * FROM catalog_vehicles ORDER BY name").fetchall()
    conn.close()
    items = [dict(r) for r in rows]
    if search:
        q = search.strip().lower()
        items = [
            v
            for v in items
            if q in v["name"].lower() or q in (v.get("subtitle") or "").lower()
        ]
    return items


def get_vehicle(vehicle_id: str) -> Optional[dict]:
    conn = get_conn()
    row = conn.execute("SELECT * FROM catalog_vehicles WHERE id = ?", (vehicle_id,)).fetchone()
    if row is None:
        conn.close()
        return None
    views = conn.execute(
        """SELECT view_id AS id, name, image, sort_order
           FROM catalog_views WHERE vehicle_id = ? ORDER BY sort_order, view_id""",
        (vehicle_id,),
    ).fetchall()
    conn.close()
    vehicle = dict(row)
    return {
        **vehicle,
        "views": [dict(v) for v in views],
        "categories": _parse_vehicle_categories(vehicle.get("categories_json")),
    }


def get_hotspots(vehicle_id: str, view_id: str, category: Optional[str] = None) -> list[dict]:
    conn = get_conn()
    rows = conn.execute(
        """SELECT h.*, GROUP_CONCAT(hp.product_id) AS product_ids_csv
           FROM catalog_hotspots h
           LEFT JOIN catalog_hotspot_products hp
             ON hp.vehicle_id = h.vehicle_id
            AND hp.view_id = h.view_id
            AND hp.hotspot_id = h.id
           WHERE h.vehicle_id = ? AND h.view_id = ?
           GROUP BY h.vehicle_id, h.view_id, h.id
           ORDER BY h.label""",
        (vehicle_id, view_id),
    ).fetchall()
    conn.close()
    hotspots = []
    for row in rows:
        product_ids = _parse_product_ids(row["product_ids_csv"])
        h = {
            "id": row["id"],
            "label": row["label"],
            "category": row["category"],
            "x": row["x"],
            "y": row["y"],
            "part_number": row["part_number"],
            "oem": row["oem"],
            "product_id": product_ids[0] if product_ids else 0,
            "product_ids": product_ids,
        }
        if category and h["category"] != category:
            continue
        hotspots.append(h)
    return hotspots


def _parse_product_ids(csv_val: Any) -> list[int]:
    if not csv_val:
        return []
    return [int(x) for x in str(csv_val).split(",") if x.strip().isdigit()]


def search_hotspots(vehicle_id: str, query: str) -> list[dict]:
    q = query.strip().lower()
    if not q:
        return []
    vehicle = get_vehicle(vehicle_id)
    if not vehicle:
        return []
    results = []
    for view in vehicle["views"]:
        for h in get_hotspots(vehicle_id, view["id"]):
            haystack = f"{h['label']} {h.get('part_number', '')} {h.get('oem', '')}".lower()
            if q in haystack:
                results.append({**h, "view_id": view["id"]})
    return results


def get_hotspot_with_products(vehicle_id: str, view_id: str, hotspot_id: str) -> Optional[dict]:
    conn = get_conn()
    row = conn.execute(
        """SELECT * FROM catalog_hotspots
           WHERE vehicle_id = ? AND view_id = ? AND id = ?""",
        (vehicle_id, view_id, hotspot_id),
    ).fetchone()
    if row is None:
        conn.close()
        return None

    product_rows = conn.execute(
        """SELECT p.* FROM catalog_hotspot_products hp
           JOIN products p ON p.id = hp.product_id
           WHERE hp.vehicle_id = ? AND hp.view_id = ? AND hp.hotspot_id = ?
           ORDER BY hp.sort_order, hp.product_id""",
        (vehicle_id, view_id, hotspot_id),
    ).fetchall()
    conn.close()

    product_ids = [r["id"] for r in product_rows]
    hotspot = {
        "id": row["id"],
        "label": row["label"],
        "category": row["category"],
        "x": row["x"],
        "y": row["y"],
        "part_number": row["part_number"],
        "oem": row["oem"],
        "product_id": product_ids[0] if product_ids else 0,
        "product_ids": product_ids,
    }
    products = [row_to_product(r) for r in product_rows]
    return {"hotspot": hotspot, "products": products}


def admin_list_catalogs() -> list[dict]:
    conn = get_conn()
    rows = conn.execute(
        """SELECT v.*,
                  (SELECT COUNT(*) FROM catalog_views cv WHERE cv.vehicle_id = v.id) AS view_count,
                  (SELECT COUNT(*) FROM catalog_hotspots ch WHERE ch.vehicle_id = v.id) AS hotspot_count
           FROM catalog_vehicles v
           ORDER BY v.updated_at DESC"""
    ).fetchall()
    conn.close()
    return [dict(r) for r in rows]


def admin_get_catalog(vehicle_id: str) -> Optional[dict]:
    vehicle = get_vehicle(vehicle_id)
    if vehicle is None:
        return None
    conn = get_conn()
    for view in vehicle["views"]:
        view_id = view["id"]
        hotspots = get_hotspots(vehicle_id, view_id)
        view["hotspots"] = hotspots
    conn.close()
    return vehicle


def _slugify(text: str) -> str:
    base = text.strip().lower().replace(" ", "-")
    safe = "".join(c for c in base if c.isalnum() or c in "-_")
    return safe or f"catalog-{uuid.uuid4().hex[:8]}"


def admin_save_catalog(payload: dict) -> dict:
    vehicle_id = payload.get("id") or _slugify(payload["name"])
    now = _now()
    conn = get_conn()
    cur = conn.cursor()
    existing = cur.execute("SELECT id FROM catalog_vehicles WHERE id = ?", (vehicle_id,)).fetchone()

    categories_json = _serialize_categories(payload.get("categories") or [])

    if existing:
        cur.execute(
            """UPDATE catalog_vehicles
               SET name=?, subtitle=?, year=?, brand_logo=?, image=?, categories_json=?, updated_at=?
               WHERE id=?""",
            (
                payload["name"],
                payload.get("subtitle", ""),
                payload.get("year", ""),
                payload.get("brand_logo", ""),
                payload.get("image", ""),
                categories_json,
                now,
                vehicle_id,
            ),
        )
        cur.execute("DELETE FROM catalog_hotspot_products WHERE vehicle_id = ?", (vehicle_id,))
        cur.execute("DELETE FROM catalog_hotspots WHERE vehicle_id = ?", (vehicle_id,))
        cur.execute("DELETE FROM catalog_views WHERE vehicle_id = ?", (vehicle_id,))
    else:
        cur.execute(
            """INSERT INTO catalog_vehicles
            (id, name, subtitle, year, brand_logo, image, categories_json, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                vehicle_id,
                payload["name"],
                payload.get("subtitle", ""),
                payload.get("year", ""),
                payload.get("brand_logo", ""),
                payload.get("image", ""),
                categories_json,
                now,
                now,
            ),
        )

    for sort_order, view in enumerate(payload.get("views", [])):
        view_id = view.get("id") or f"view-{sort_order}"
        cur.execute(
            """INSERT INTO catalog_views (vehicle_id, view_id, name, image, sort_order)
            VALUES (?, ?, ?, ?, ?)""",
            (vehicle_id, view_id, view["name"], view.get("image", ""), sort_order),
        )
        for hotspot in view.get("hotspots", []):
            hid = hotspot.get("id") or f"hs-{uuid.uuid4().hex[:8]}"
            cur.execute(
                """INSERT INTO catalog_hotspots
                (vehicle_id, view_id, id, label, category, x, y, part_number, oem)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                (
                    vehicle_id,
                    view_id,
                    hid,
                    hotspot["label"],
                    hotspot.get("category", "body"),
                    float(hotspot["x"]),
                    float(hotspot["y"]),
                    hotspot.get("part_number", ""),
                    hotspot.get("oem", ""),
                ),
            )
            product_ids = hotspot.get("product_ids") or []
            if not product_ids and hotspot.get("product_id"):
                product_ids = [hotspot["product_id"]]
            for p_sort, pid in enumerate(product_ids):
                cur.execute(
                    """INSERT INTO catalog_hotspot_products
                    (vehicle_id, view_id, hotspot_id, product_id, sort_order)
                    VALUES (?, ?, ?, ?, ?)""",
                    (vehicle_id, view_id, hid, int(pid), p_sort),
                )

    conn.commit()
    conn.close()
    saved = admin_get_catalog(vehicle_id)
    return saved or {"id": vehicle_id}


def admin_delete_catalog(vehicle_id: str) -> bool:
    conn = get_conn()
    row = conn.execute("SELECT id FROM catalog_vehicles WHERE id = ?", (vehicle_id,)).fetchone()
    if row is None:
        conn.close()
        return False
    conn.execute("DELETE FROM catalog_vehicles WHERE id = ?", (vehicle_id,))
    conn.commit()
    conn.close()
    return True
