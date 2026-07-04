"""Data-driven smart parts catalog — add vehicles/views/hotspots here without UI changes."""

CATALOG_CATEGORIES = [
    {"id": "lights", "name": "چراغ‌ها", "icon": "light"},
    {"id": "bumpers", "name": "سپرها", "icon": "bumper"},
    {"id": "engine", "name": "موتور", "icon": "engine"},
    {"id": "suspension", "name": "سیستم تعلیق", "icon": "suspension"},
    {"id": "brake", "name": "سیستم ترمز", "icon": "brake"},
    {"id": "electrical", "name": "برق خودرو", "icon": "electrical"},
    {"id": "filters", "name": "فیلترها", "icon": "filter"},
    {"id": "oils", "name": "روغن‌ها", "icon": "oil"},
    {"id": "body", "name": "بدنه", "icon": "body"},
    {"id": "gearbox", "name": "گیربکس", "icon": "gearbox"},
]

VIEW_DEFINITIONS = [
    {"id": "front", "name": "نمای جلو"},
    {"id": "rear", "name": "نمای عقب"},
    {"id": "right_side", "name": "نمای جانبی راست"},
    {"id": "left_side", "name": "نمای جانبی چپ"},
    {"id": "exterior", "name": "نمای بیرونی"},
    {"id": "interior", "name": "نمای داخل کابین"},
    {"id": "engine", "name": "نمای موتور"},
    {"id": "suspension", "name": "سیستم تعلیق"},
    {"id": "brake", "name": "سیستم ترمز"},
]

# Hotspots for peugeot-206 front/exterior views (x,y as 0–1 fractions)
_PEUGEOT_206_FRONT_HOTSPOTS = [
    {"id": "206-hl-r", "label": "چراغ جلو راست", "category": "lights", "x": 0.73, "y": 0.42, "product_id": 85, "part_number": "206-12-RT", "oem": "VAL-206-HL-R"},
    {"id": "206-hl-l", "label": "چراغ جلو چپ", "category": "lights", "x": 0.27, "y": 0.42, "product_id": 85, "part_number": "206-12-LT", "oem": "VAL-206-HL-L"},
    {"id": "206-bumper", "label": "سپر جلو", "category": "bumpers", "x": 0.50, "y": 0.62, "product_id": 86, "part_number": "206-BP-F", "oem": "206-BUMPER-F"},
    {"id": "206-hood", "label": "کاپوت", "category": "body", "x": 0.50, "y": 0.32, "product_id": 87, "part_number": "206-HOOD", "oem": "206-HOOD-01"},
    {"id": "206-radiator", "label": "رادیاتور", "category": "engine", "x": 0.50, "y": 0.52, "product_id": 88, "part_number": "206-RAD", "oem": "206-RADIATOR"},
    {"id": "206-mirror-r", "label": "آینه بغل راست", "category": "body", "x": 0.88, "y": 0.36, "product_id": 89, "part_number": "206-MR-R", "oem": "206-MIRROR-R"},
    {"id": "206-mirror-l", "label": "آینه بغل چپ", "category": "body", "x": 0.12, "y": 0.36, "product_id": 89, "part_number": "206-MR-L", "oem": "206-MIRROR-L"},
    {"id": "206-door-r", "label": "درب جلو راست", "category": "body", "x": 0.78, "y": 0.48, "product_id": 90, "part_number": "206-DR-R", "oem": "206-DOOR-R"},
    {"id": "206-wheel-r", "label": "چرخ جلو راست", "category": "suspension", "x": 0.76, "y": 0.74, "product_id": 91, "part_number": "206-WH-R", "oem": "206-WHEEL-R"},
    {"id": "206-wheel-l", "label": "چرخ جلو چپ", "category": "suspension", "x": 0.24, "y": 0.74, "product_id": 91, "part_number": "206-WH-L", "oem": "206-WHEEL-L"},
    {"id": "206-brake", "label": "دیسک ترمز جلو", "category": "brake", "x": 0.68, "y": 0.70, "product_id": 82, "part_number": "206-BRK-D", "oem": "206-BRAKE-DISC"},
    {"id": "206-filter", "label": "فیلتر هوا", "category": "filters", "x": 0.42, "y": 0.48, "product_id": 84, "part_number": "206-AF", "oem": "206-AIR-FILTER"},
    {"id": "206-battery", "label": "باتری", "category": "electrical", "x": 0.58, "y": 0.48, "product_id": 95, "part_number": "206-BAT", "oem": "206-BATTERY"},
    {"id": "206-wiper", "label": "موتور برف‌پاک‌کن", "category": "electrical", "x": 0.50, "y": 0.28, "product_id": 96, "part_number": "206-WIP", "oem": "206-WIPER"},
    {"id": "206-shock", "label": "کمک فنر جلو", "category": "suspension", "x": 0.72, "y": 0.58, "product_id": 88, "part_number": "206-SHK-F", "oem": "206-SHOCK-F"},
]

_PEUGEOT_206_REAR_HOTSPOTS = [
    {"id": "206-tl-r", "label": "چراغ عقب راست", "category": "lights", "x": 0.72, "y": 0.44, "product_id": 85, "part_number": "206-TL-R", "oem": "206-TAIL-R"},
    {"id": "206-tl-l", "label": "چراغ عقب چپ", "category": "lights", "x": 0.28, "y": 0.44, "product_id": 85, "part_number": "206-TL-L", "oem": "206-TAIL-L"},
    {"id": "206-trunk", "label": "صندوق عقب", "category": "body", "x": 0.50, "y": 0.38, "product_id": 87, "part_number": "206-TRK", "oem": "206-TRUNK"},
    {"id": "206-bumper-r", "label": "سپر عقب", "category": "bumpers", "x": 0.50, "y": 0.60, "product_id": 86, "part_number": "206-BP-R", "oem": "206-BUMPER-R"},
]

def _view_image(vehicle_id: str, view_id: str) -> str:
    return f"https://picsum.photos/seed/{vehicle_id}-{view_id}/1200/700"


def _hotspots_for(vehicle_id: str, view_id: str) -> list[dict]:
    if vehicle_id == "peugeot-206":
        if view_id in ("front", "exterior"):
            return _PEUGEOT_206_FRONT_HOTSPOTS
        if view_id == "rear":
            return _PEUGEOT_206_REAR_HOTSPOTS
    # Default: reuse front layout for other vehicles/views (scalable placeholder)
    if view_id in ("front", "exterior", "right_side", "left_side"):
        base = _PEUGEOT_206_FRONT_HOTSPOTS[:8]
        return [{**h, "id": f"{vehicle_id}-{h['id']}"} for h in base]
    if view_id == "rear":
        base = _PEUGEOT_206_REAR_HOTSPOTS
        return [{**h, "id": f"{vehicle_id}-{h['id']}"} for h in base]
    return []


CATALOG_VEHICLES = [
    {
        "id": "peugeot-206",
        "name": "پژو ۲۰۶",
        "subtitle": "سدان / هاچبک",
        "year": "۱۳۸۰–۱۴۰۰",
        "brand_logo": "https://picsum.photos/seed/peugeot-logo/80/40",
        "image": "https://picsum.photos/seed/peugeot206-card/400/240",
        "views": [
            {"id": v["id"], "name": v["name"], "image": _view_image("peugeot-206", v["id"])}
            for v in VIEW_DEFINITIONS
        ],
    },
    {
        "id": "peugeot-pars",
        "name": "پژو پارس",
        "subtitle": "سدان",
        "year": "۱۳۸۰–۱۳۹۹",
        "brand_logo": "https://picsum.photos/seed/peugeot-logo/80/40",
        "image": "https://picsum.photos/seed/peugeotpars-card/400/240",
        "views": [
            {"id": v["id"], "name": v["name"], "image": _view_image("peugeot-pars", v["id"])}
            for v in VIEW_DEFINITIONS[:6]
        ],
    },
    {
        "id": "peugeot-405",
        "name": "پژو ۴۰۵",
        "subtitle": "سدان",
        "year": "۱۳۶۹–۱۳۸۹",
        "brand_logo": "https://picsum.photos/seed/peugeot-logo/80/40",
        "image": "https://picsum.photos/seed/peugeot405-card/400/240",
        "views": [
            {"id": v["id"], "name": v["name"], "image": _view_image("peugeot-405", v["id"])}
            for v in VIEW_DEFINITIONS[:6]
        ],
    },
    {
        "id": "samand-ef7",
        "name": "سمند EF7",
        "subtitle": "سدان",
        "year": "۱۳۸۹–۱۴۰۲",
        "brand_logo": "https://picsum.photos/seed/ikco-logo/80/40",
        "image": "https://picsum.photos/seed/samand-card/400/240",
        "views": [
            {"id": v["id"], "name": v["name"], "image": _view_image("samand-ef7", v["id"])}
            for v in VIEW_DEFINITIONS[:6]
        ],
    },
    {
        "id": "dena-plus",
        "name": "دنا پلاس",
        "subtitle": "سدان",
        "year": "۱۳۹۶–۱۴۰۳",
        "brand_logo": "https://picsum.photos/seed/ikco-logo/80/40",
        "image": "https://picsum.photos/seed/dena-card/400/240",
        "views": [
            {"id": v["id"], "name": v["name"], "image": _view_image("dena-plus", v["id"])}
            for v in VIEW_DEFINITIONS[:6]
        ],
    },
    {
        "id": "rana",
        "name": "رانا",
        "subtitle": "سدان",
        "year": "۱۳۹۱–۱۴۰۲",
        "brand_logo": "https://picsum.photos/seed/saipa-logo/80/40",
        "image": "https://picsum.photos/seed/rana-card/400/240",
        "views": [
            {"id": v["id"], "name": v["name"], "image": _view_image("rana", v["id"])}
            for v in VIEW_DEFINITIONS[:6]
        ],
    },
    {
        "id": "tara",
        "name": "تارا",
        "subtitle": "سدان",
        "year": "۱۴۰۰–۱۴۰۳",
        "brand_logo": "https://picsum.photos/seed/saipa-logo/80/40",
        "image": "https://picsum.photos/seed/tara-card/400/240",
        "views": [
            {"id": v["id"], "name": v["name"], "image": _view_image("tara", v["id"])}
            for v in VIEW_DEFINITIONS[:6]
        ],
    },
    {
        "id": "shahin",
        "name": "شاهین",
        "subtitle": "سدان",
        "year": "۱۳۹۹–۱۴۰۳",
        "brand_logo": "https://picsum.photos/seed/saipa-logo/80/40",
        "image": "https://picsum.photos/seed/shahin-card/400/240",
        "views": [
            {"id": v["id"], "name": v["name"], "image": _view_image("shahin", v["id"])}
            for v in VIEW_DEFINITIONS[:6]
        ],
    },
]


def get_vehicle(vehicle_id: str) -> dict | None:
    for v in CATALOG_VEHICLES:
        if v["id"] == vehicle_id:
            return v
    return None


def get_hotspots(vehicle_id: str, view_id: str) -> list[dict]:
    return _hotspots_for(vehicle_id, view_id)


def search_hotspots(vehicle_id: str, query: str) -> list[dict]:
    q = query.strip().lower()
    if not q:
        return []
    results = []
    vehicle = get_vehicle(vehicle_id)
    if not vehicle:
        return []
    for view in vehicle["views"]:
        for h in _hotspots_for(vehicle_id, view["id"]):
            haystack = f"{h['label']} {h.get('part_number','')} {h.get('oem','')}".lower()
            if q in haystack:
                results.append({**h, "view_id": view["id"]})
    return results
