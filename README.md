# جهانگیری — Car Spare Parts E-Commerce Platform

فروشگاه آنلاین قطعات یدکی خودرو با **Flutter Web** (فرانت‌اند) و **FastAPI + SQLite** (بک‌اند).

Remote: [kiddo-from-iran/Car-Spare-Parts-E-Commerce-Platform](https://github.com/kiddo-from-iran/Car-Spare-Parts-E-Commerce-Platform)

---

## Tech stack

| Layer | Stack |
|-------|--------|
| Frontend | Flutter 3, Provider, GoRouter, Lottie, flutter_map |
| Backend | FastAPI, Pydantic, SQLite, JWT auth |
| API | REST — base URL `http://localhost:8000` |

---

## Quick start

### Prerequisites

- Python 3.10+
- Flutter SDK 3.10+
- Chrome / Edge (for web)

### Backend

```powershell
cd backend
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

API docs: [http://localhost:8000/docs](http://localhost:8000/docs)

On first run, SQLite (`backend/shop.db`) is created and seeded with sample products, users, discounts, and smart-catalog data.

### Frontend

```powershell
cd frontend
flutter pub get
flutter run -d chrome
# or: flutter run -d edge
```

The app talks to `http://localhost:8000` by default (`lib/services/api_service.dart`).

---

## Default accounts

| Role | Phone | Password |
|------|-------|----------|
| Admin | `09120000000` | `admin123` |
| User | `09121111111` | `user123` |

---

## Features

### Storefront

- Home page with hero slider, vehicle/part categories, partner brands, featured products
- Shop with filters (category, vehicle, part type), sort, pagination, live search
- Product detail with specs, stock availability, cart limits, wishlist
- Smart catalog (`/smart-catalog`) — interactive vehicle diagrams with clickable hotspots and multi-product specs
- Checkout with saved addresses, discount codes, shipping options
- About & contact pages
- Global Lottie loading animation

### User account (`/account`)

- Dashboard with orders table and stats
- Profile + saved addresses (map picker dialog: title, address text, location on map)
- Support tickets tied to **active orders** (not delivered / not cancelled)
- Wishlist & notifications

### Admin panel (`/admin`)

- Dashboard & revenue charts
- Orders management
- Products CRUD with stock quantity
- **Smart catalog management** — upload diagram images, place hotspot dots, assign one or more products per dot
- Support tickets

---

## Main routes

| Path | Description |
|------|-------------|
| `/` | Home |
| `/shop` | Product listing |
| `/smart-catalog` | Interactive parts catalog |
| `/product/:id` | Product detail |
| `/checkout` | Checkout (login required) |
| `/account` | User dashboard |
| `/account/profile` | Profile & addresses |
| `/account/tickets` | Order-based support |
| `/admin` | Admin dashboard |
| `/admin/products` | Product management |
| `/admin/catalogs` | Smart catalog editor |

---

## Project structure

```
roozbeh/
├── backend/
│   ├── main.py              # FastAPI app entry
│   ├── database.py          # SQLite schema & migrations
│   ├── catalog_db.py        # Smart catalog persistence
│   ├── routers/             # API routes
│   ├── data/                # Seed data
│   └── static/catalog/      # Uploaded catalog images
├── frontend/
│   └── lib/
│       ├── pages/           # Screens (shop, admin, account, …)
│       ├── widgets/         # Shared UI (incl. app_loading_indicator)
│       ├── services/        # API client
│       └── assets/lottie/   # Loading animation (maintain.json)
└── README.md
```

---

## Smart catalog (admin)

1. Go to **Admin → کاتالوگ هوشمند**
2. Create a catalog, upload a view image
3. Click on the image to place hotspot circles
4. Set each hotspot title and assign one or more products (search)
5. Save — catalog appears on `/smart-catalog` for customers

---

## License

Private / educational project — see repository owner for usage terms.
