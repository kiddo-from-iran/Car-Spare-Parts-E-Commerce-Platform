"""Category data for جهانگیری car spare parts store."""

VEHICLE_CATEGORIES = [
    {"id": "peugeot-405", "name": "پژو ۴۰۵", "image": "https://picsum.photos/seed/peugeot405/200/200"},
    {"id": "peugeot-pars", "name": "پژو پارس", "image": "https://picsum.photos/seed/peugeotpars/200/200"},
    {"id": "samand", "name": "سمند", "image": "https://picsum.photos/seed/samand/200/200"},
    {"id": "samand-soren", "name": "سمند سورن", "image": "https://picsum.photos/seed/soren/200/200"},
    {"id": "peugeot-206", "name": "پژو ۲۰۶", "image": "https://picsum.photos/seed/peugeot206/200/200"},
    {"id": "peugeot-206sd", "name": "پژو ۲۰۶ SD", "image": "https://picsum.photos/seed/peugeot206sd/200/200"},
    {"id": "peugeot-207", "name": "پژو ۲۰۷", "image": "https://picsum.photos/seed/peugeot207/200/200"},
    {"id": "pride", "name": "پراید", "image": "https://picsum.photos/seed/pride/200/200"},
    {"id": "tiba", "name": "تیبا", "image": "https://picsum.photos/seed/tiba/200/200"},
    {"id": "dena", "name": "دنا", "image": "https://picsum.photos/seed/dena/200/200"},
]

PART_CATEGORIES = [
    {"id": "engine", "name": "قطعات موتوری", "image": "https://picsum.photos/seed/engine/200/200"},
    {"id": "suspension", "name": "جلوبندی و تعلیق", "image": "https://picsum.photos/seed/suspension/200/200"},
    {"id": "consumables", "name": "قطعات مصرفی", "image": "https://picsum.photos/seed/consumables/200/200"},
    {"id": "electrical", "name": "قطعات برقی", "image": "https://picsum.photos/seed/electrical/200/200"},
    {"id": "brake", "name": "ترمز و کلاچ", "image": "https://picsum.photos/seed/brake/200/200"},
    {"id": "body", "name": "بدنه و شیشه", "image": "https://picsum.photos/seed/body/200/200"},
    {"id": "filter", "name": "فیلترها", "image": "https://picsum.photos/seed/filter/200/200"},
    {"id": "belt", "name": "تسمه و پولی", "image": "https://picsum.photos/seed/belt/200/200"},
]

MEGA_MENU = [
    {
        "id": "car-parts",
        "name": "قطعات خودرو",
        "icon": "build",
        "subcategories": [
            {
                "name": "قطعات موتوری",
                "slug": "engine",
                "items": [
                    "تسمه تایم",
                    "تسمه دینام",
                    "وایر شمع",
                    "واترپمپ",
                    "درپوش رادیاتور",
                    "سنسور MAP",
                    "سنسور MAF",
                    "واشر سرسیلندر",
                ],
            },
            {
                "name": "جلوبندی و تعلیق",
                "slug": "suspension",
                "items": [
                    "کامل جلوبندی",
                    "کمک فنر",
                    "بلبرینگ چرخ",
                    "سیبک فرمان",
                    "طبق",
                    "بوش طبق",
                    "میل موجگیر",
                ],
            },
            {
                "name": "قطعات مصرفی",
                "slug": "consumables",
                "items": [
                    "لنت ترمز",
                    "دیسک ترمز",
                    "شمع",
                    "فیلتر بنزین",
                    "فیلتر روغن",
                    "فیلتر هوا",
                    "فیلتر کابین",
                ],
            },
            {
                "name": "قطعات برقی",
                "slug": "electrical",
                "items": [
                    "استارت",
                    "پمپ بنزین",
                    "پمپ شیشه‌شور",
                    "دینام",
                    "سنسور ABS",
                    "سنسور اکسیژن",
                    "رله و فیوز",
                ],
            },
        ],
    },
    {
        "id": "oils",
        "name": "روغن و روان‌کننده‌ها",
        "icon": "opacity",
        "subcategories": [
            {
                "name": "روغن موتور",
                "slug": "engine-oil",
                "items": ["روغن ۵W30", "روغن 10W40", "روغن 20W50", "روغن سنتتیک"],
            },
            {
                "name": "روغن گیربکس",
                "slug": "gearbox-oil",
                "items": ["روغن ATF", "روغن گیربکس دستی", "روغن دیفرانسیل"],
            },
        ],
    },
    {
        "id": "maintenance",
        "name": "نظافت و نگهداری خودرو",
        "icon": "cleaning_services",
        "subcategories": [
            {
                "name": "محصولات نظافتی",
                "slug": "cleaning",
                "items": ["شampoo خودرو", "واکس", "پولisher", "مایع شیشه‌شور"],
            },
        ],
    },
    {
        "id": "additives",
        "name": "اکتان و مکمل‌ها",
        "icon": "science",
        "subcategories": [
            {
                "name": "مکمل سوخت",
                "slug": "fuel-additives",
                "items": ["اکتان بوستر", "تمیزکننده انژکتور", "ضد یخ"],
            },
        ],
    },
    {
        "id": "fresheners",
        "name": "خوشبوکننده",
        "icon": "air",
        "subcategories": [
            {
                "name": "خوشبوکننده خودرو",
                "slug": "fresheners",
                "items": ["اسپری", "آویز", "ژل"],
            },
        ],
    },
]

BRANDS = [
    "ایساکو",
    "سایپا",
    "پارس‌خودرو",
    "بوش",
    "NGK",
    "MANN",
    "Brembo",
    "Valeo",
    "Denso",
    "Mobil",
    "Total",
    "Castrol",
]

MANUFACTURER_COUNTRIES = ["ایران", "چین", "ژاپن", "کره", "آلمان", "فرانسه", "ایتالیا"]

SPARE_PART_CATEGORIES = [c["name"] for c in PART_CATEGORIES]

PARTNER_BRANDS = [
    {"id": "isaco", "name": "ایساکو", "logo": "https://picsum.photos/seed/brand-isaco/180/80"},
    {"id": "saipa", "name": "سایپا", "logo": "https://picsum.photos/seed/brand-saipa/180/80"},
    {"id": "pars-khodro", "name": "پارس‌خودرو", "logo": "https://picsum.photos/seed/brand-pars/180/80"},
    {"id": "bosch", "name": "بوش", "logo": "https://picsum.photos/seed/brand-bosch/180/80"},
    {"id": "ngk", "name": "NGK", "logo": "https://picsum.photos/seed/brand-ngk/180/80"},
    {"id": "mann", "name": "MANN", "logo": "https://picsum.photos/seed/brand-mann/180/80"},
    {"id": "brembo", "name": "Brembo", "logo": "https://picsum.photos/seed/brand-brembo/180/80"},
    {"id": "valeo", "name": "Valeo", "logo": "https://picsum.photos/seed/brand-valeo/180/80"},
    {"id": "denso", "name": "Denso", "logo": "https://picsum.photos/seed/brand-denso/180/80"},
    {"id": "mobil", "name": "Mobil", "logo": "https://picsum.photos/seed/brand-mobil/180/80"},
    {"id": "castrol", "name": "Castrol", "logo": "https://picsum.photos/seed/brand-castrol/180/80"},
    {"id": "total", "name": "Total", "logo": "https://picsum.photos/seed/brand-total/180/80"},
]
