"""Seed data generator for car spare parts products."""

from datetime import datetime, timedelta

VEHICLES = [
    "پژو ۴۰۵", "پژو پارس", "سمند", "سمند سورن", "پژو ۲۰۶",
    "پژو ۲۰۶ SD", "پژو ۲۰۷", "پراید", "تیبا", "دنا",
]

PART_CATS = [
    "قطعات موتوری", "جلوبندی و تعلیق", "قطعات مصرفی",
    "قطعات برقی", "ترمز و کلاچ", "فیلترها",
]

BRANDS = ["ایساکو", "سایپا", "بوش", "NGK", "MANN", "Brembo", "Valeo", "Denso"]
COUNTRIES = ["ایران", "چین", "ژاپن", "کره", "آلمان"]

PRODUCT_TEMPLATES = [
    ("لنت ترمز جلو", "لنت ترمز با کیفیت بالا، مقاوم در برابر حرارت", "قطعات مصرفی", 850000, 15),
    ("دیسک ترمز", "دیسک ترمز اورجینال با دوام بالا", "قطعات مصرفی", 1200000, 10),
    ("فیلتر روغن", "فیلتر روغن با کیفیت OEM", "فیلترها", 180000, 0),
    ("فیلتر هوا", "فیلتر هوای با بازدهی بالا", "فیلترها", 220000, 5),
    ("فیلتر بنزین", "فیلتر بنزین با دوام طولانی", "فیلترها", 150000, 0),
    ("شمع NGK", "شمع احتراق NGK اورجینال", "قطعات مصرفی", 320000, 0),
    ("تسمه تایم", "تسمه تایم تقویت‌شده", "قطعات موتوری", 980000, 12),
    ("تسمه دینام", "تسمه دینام با کیفیت بالا", "قطعات موتوری", 280000, 0),
    ("واترپمپ", "واترپمپ با بلبرینگ سرامیکی", "قطعات موتوری", 1450000, 8),
    ("کمک فنر جلو", "کمک فنر گازی با عملکرد نرم", "جلوبندی و تعلیق", 2100000, 10),
    ("کمک فنر عقب", "کمک فنر عقب OEM", "جلوبندی و تعلیق", 1850000, 10),
    ("بلبرینگ چرخ جلو", "بلبرینگ چرخ با دوام بالا", "جلوبندی و تعلیق", 650000, 0),
    ("سیبک فرمان", "سیبک فرمان تقویت‌شده", "جلوبندی و تعلیق", 420000, 5),
    ("طبق جلو", "طبق فلزی با بوش پلی‌اورتان", "جلوبندی و تعلیق", 780000, 0),
    ("استارت", "استارت ۱.۴kW با گارانتی", "قطعات برقی", 3200000, 15),
    ("دینام", "دینام ۹۰ آمپر", "قطعات برقی", 2800000, 12),
    ("پمپ بنزین", "پمپ بنزین برقی در مخزن", "قطعات برقی", 1650000, 8),
    ("سنسور اکسیژن", "سنسور O2 lambda", "قطعات برقی", 890000, 0),
    ("سنسور ABS", "سنسور سرعت چرخ ABS", "قطعات برقی", 720000, 5),
    ("کیت کلاچ", "کیت کلاچ کامل شامل دیسک و صفحه", "ترمز و کلاچ", 4500000, 18),
]


def generate_products() -> list[dict]:
    products = []
    now = datetime.now()
    pid = 1

    for vi, vehicle in enumerate(VEHICLES):
        for ti, (name, desc, cat, base_price, discount) in enumerate(PRODUCT_TEMPLATES):
            brand = BRANDS[(vi + ti) % len(BRANDS)]
            country = COUNTRIES[(vi + ti) % len(COUNTRIES)]
            price_variation = (vi * 7 + ti * 13) % 500000
            price = base_price + price_variation
            original = price if discount == 0 else int(price / (1 - discount / 100))
            vehicles = [vehicle]
            if ti % 3 == 0 and vi + 1 < len(VEHICLES):
                vehicles.append(VEHICLES[vi + 1])

            products.append({
                "name": f"{name} {vehicle}",
                "price": float(price),
                "original_price": float(original),
                "discount_percent": float(discount),
                "description": f"{desc}. سازگار با {vehicle}. برند {brand}.",
                "category": cat,
                "part_category": cat,
                "brand": brand,
                "manufacturer_country": country,
                "compatible_vehicles": vehicles,
                "colors": ["استاندارد"],
                "sizes": ["استاندارد"],
                "images": [
                    f"https://picsum.photos/seed/sp{pid}a/800/800",
                    f"https://picsum.photos/seed/sp{pid}b/800/800",
                ],
                "specs": {
                    "برند": brand,
                    "کشور سازنده": country,
                    "گارانتی": "۶ ماه",
                    "کد فنی": f"JG-{pid:04d}",
                },
                "popularity": 100 - (pid % 50),
                "views": 500 + pid * 17,
                "rating": round(3.5 + (pid % 15) / 10, 1),
                "review_count": 5 + pid % 40,
                "stock_quantity": 0 if pid % 17 == 0 else 10 + pid % 50,
                "is_new": pid % 8 == 0,
                "in_stock": pid % 17 != 0,
                "created_at": (now - timedelta(days=pid)).isoformat(),
            })
            pid += 1

    return products
