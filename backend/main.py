from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from database import init_db
from routers.admin_catalog import router as admin_catalog_router
from routers.admin_stats import admin_stats_router
from routers.auth import router as auth_router
from routers.catalog import admin_products_router, products_router
from routers.discounts import router as discounts_router
from routers.orders import admin_router as admin_orders_router, router as orders_router
from routers.smart_catalog import router as smart_catalog_router
from routers.tickets import admin_router as admin_tickets_router, router as tickets_router

app = FastAPI(title="جهانگیری API", version="3.0.0")

# Bearer-token auth only (no cookies). Wildcard origin for GitHub Pages + local dev.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)


@app.get("/api/health")
def health():
    return {"status": "ok"}


@app.on_event("startup")
def startup():
    init_db()
    static_dir = Path(__file__).parent / "static"
    static_dir.mkdir(exist_ok=True)
    (static_dir / "catalog").mkdir(exist_ok=True)


_static_dir = Path(__file__).parent / "static"
if _static_dir.exists():
    app.mount("/static", StaticFiles(directory=str(_static_dir)), name="static")


app.include_router(admin_stats_router)
app.include_router(admin_catalog_router)
app.include_router(auth_router)
app.include_router(discounts_router)
app.include_router(products_router)
app.include_router(admin_products_router)
app.include_router(orders_router)
app.include_router(admin_orders_router)
app.include_router(smart_catalog_router)
app.include_router(tickets_router)
app.include_router(admin_tickets_router)
