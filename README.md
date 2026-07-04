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

## Live deployment (GitHub Pages + Render)

After pushing to GitHub, the site is published automatically:

| | URL |
|---|-----|
| **Website (Flutter Web)** | `https://kiddo-from-iran.github.io/Car-Spare-Parts-E-Commerce-Platform/` |
| **API (FastAPI on Render)** | `https://car-spare-parts-api.onrender.com` |
| **API docs** | `https://car-spare-parts-api.onrender.com/docs` |

Open the website link on any phone or PC. Use hash routes, e.g.  
`https://kiddo-from-iran.github.io/Car-Spare-Parts-E-Commerce-Platform/#/smart-catalog`

### One-time setup (repo owner)

1. **Push** this repo to GitHub (`master` branch).
2. **GitHub Pages:** Repository → **Settings → Pages → Build and deployment → Source:** `GitHub Actions`.
3. **Backend on Render** (free tier):
   - [render.com](https://render.com) → **New → Blueprint**
   - Connect repo `kiddo-from-iran/Car-Spare-Parts-E-Commerce-Platform`
   - Apply `render.yaml` (service name `car-spare-parts-api`)
   - Wait until deploy is live; note the URL (default above).
4. **Optional:** Repository → **Settings → Secrets and variables → Actions → Variables**  
   Add `API_BASE_URL` = your Render URL if it differs from the default.
5. Re-run **Deploy GitHub Pages** workflow (Actions tab) or push a commit.

### Troubleshooting production

| Symptom | Cause | Fix |
|---------|--------|-----|
| Browser console: **CORS blocked** on `car-spare-parts-api.onrender.com` | Backend not running (Render returns `404` / `x-render-routing: no-server`) | Complete step 3 above — create the Render service from `render.yaml` |
| No products / empty shop | Same — frontend cannot reach API | After Render is live, open `/api/health` and `/docs`; first free-tier request may take ~30s |
| Local carousel images 404 (`lib/assets/images/...`) | Flutter web + GitHub Pages subpath | Fixed in `CatalogAssetImage` (loads `assets/lib/assets/...`); push and redeploy Pages |

Verify API (replace with your Render service URL from the dashboard):

```bash
curl https://YOUR-SERVICE.onrender.com/api/health
# → {"status":"ok"}
```

If you get `Not Found` / `no-server`, the service is not live yet — check Render **Logs** for build/start errors.

Set the same URL in **`frontend/web/api-config.json`** → `"apiBaseUrl"`, then push so GitHub Pages picks it up.

### CI / CD workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `CI` | Push / PR | Python smoke test, `flutter analyze`, `test`, `build web` |
| `Deploy GitHub Pages` | Push to `master` / `main` | Builds Flutter web and publishes to GitHub Pages |

### Local build matching production

```powershell
cd frontend
flutter build web --release `
  --base-href "/Car-Spare-Parts-E-Commerce-Platform/" `
  --dart-define=API_BASE_URL=https://car-spare-parts-api.onrender.com
```

---

## License

Private / educational project — see repository owner for usage terms.
