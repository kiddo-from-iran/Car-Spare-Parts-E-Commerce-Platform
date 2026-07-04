from enum import Enum

from data.categories import BRANDS, MANUFACTURER_COUNTRIES, SPARE_PART_CATEGORIES


class OrderStatus(str, Enum):
    PENDING_PAYMENT = "pending_payment"
    PROCESSING = "processing"
    SHIPPED = "shipped"
    DELIVERED = "delivered"
    CANCELLED = "cancelled"


ORDER_STATUS_LABELS = {
    OrderStatus.PENDING_PAYMENT: "در انتظار پرداخت",
    OrderStatus.PROCESSING: "در حال پردازش",
    OrderStatus.SHIPPED: "ارسال شده",
    OrderStatus.DELIVERED: "تحویل داده شده",
    OrderStatus.CANCELLED: "لغو شده",
}

ACTIVE_STATUSES = {
    OrderStatus.PENDING_PAYMENT,
    OrderStatus.PROCESSING,
    OrderStatus.SHIPPED,
}

COMPLETED_STATUSES = {OrderStatus.DELIVERED, OrderStatus.CANCELLED}

ORDER_STATUS_FLOW = [
    OrderStatus.PENDING_PAYMENT,
    OrderStatus.PROCESSING,
    OrderStatus.SHIPPED,
    OrderStatus.DELIVERED,
    OrderStatus.CANCELLED,
]

CATEGORIES = SPARE_PART_CATEGORIES

FOOTER_CATEGORIES = [
    "دسته‌بندی بر اساس خودرو",
    "دسته‌بندی بر اساس قطعات",
    "فروشگاه",
]

SHIPPING_COSTS = {
    "post": 0,
    "tipax": 45000,
    "express": 85000,
}

SHIPPING_LABELS = {
    "post": "پست پیشتاز",
    "tipax": "تیپاکس",
    "express": "پیک فوری",
}

PAYMENT_METHODS = {
    "online": "پرداخت آنلاین",
    "cod": "پرداخت در محل",
    "installment": "پرداخت اقساطی",
}

BRANDS_LIST = BRANDS
MANUFACTURER_COUNTRIES_LIST = MANUFACTURER_COUNTRIES
