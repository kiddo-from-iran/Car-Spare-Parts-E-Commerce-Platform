from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from database import init_db
from routers.admin_stats import admin_stats_router
from routers.auth import router as auth_router
from routers.catalog import admin_products_router, products_router
from routers.discounts import router as discounts_router
from routers.orders import admin_router as admin_orders_router, router as orders_router
from routers.smart_catalog import router as smart_catalog_router
from routers.tickets import admin_router as admin_tickets_router, router as tickets_router

app = FastAPI(title="جهانگیری API", version="3.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def startup():
    init_db()


app.include_router(admin_stats_router)
app.include_router(auth_router)
app.include_router(discounts_router)
app.include_router(products_router)
app.include_router(admin_products_router)
app.include_router(orders_router)
app.include_router(admin_orders_router)
app.include_router(smart_catalog_router)
app.include_router(tickets_router)
app.include_router(admin_tickets_router)
