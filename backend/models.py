from typing import Optional

from pydantic import BaseModel, Field


class SearchSuggestion(BaseModel):
    id: int
    name: str
    price: float
    brand: str = ""
    category: str = ""
    image: str = ""


class PartnerBrand(BaseModel):
    id: str
    name: str
    logo: str


class CatalogVehicleSummary(BaseModel):
    id: str
    name: str
    subtitle: str = ""
    year: str = ""
    brand_logo: str = ""
    image: str


class CatalogView(BaseModel):
    id: str
    name: str
    image: str


class CatalogCategory(BaseModel):
    id: str
    name: str
    icon: str


class CatalogHotspot(BaseModel):
    id: str
    label: str
    category: str
    x: float
    y: float
    product_id: int = 0
    product_ids: list[int] = Field(default_factory=list)
    part_number: str = ""
    oem: str = ""


class CatalogHotspotInput(BaseModel):
    id: Optional[str] = None
    label: str
    category: str = "body"
    x: float
    y: float
    product_id: Optional[int] = None
    product_ids: list[int] = Field(default_factory=list)
    part_number: str = ""
    oem: str = ""


class CatalogViewInput(BaseModel):
    id: Optional[str] = None
    name: str
    image: str = ""
    hotspots: list[CatalogHotspotInput] = Field(default_factory=list)


class AdminCatalogSave(BaseModel):
    id: Optional[str] = None
    name: str
    subtitle: str = ""
    year: str = ""
    brand_logo: str = ""
    image: str = ""
    categories: list[CatalogCategory] = Field(default_factory=list)
    views: list[CatalogViewInput] = Field(default_factory=list)


class AdminCatalogSummary(BaseModel):
    id: str
    name: str
    subtitle: str = ""
    year: str = ""
    brand_logo: str = ""
    image: str = ""
    view_count: int = 0
    hotspot_count: int = 0
    created_at: str = ""
    updated_at: str = ""


class CatalogVehicle(BaseModel):
    id: str
    name: str
    subtitle: str = ""
    year: str = ""
    brand_logo: str = ""
    image: str
    views: list[CatalogView]
    categories: list[CatalogCategory] = []


class CatalogHotspotProduct(BaseModel):
    hotspot: CatalogHotspot
    product: "Product"
    products: list["Product"] = Field(default_factory=list)
    part_number: str = ""
    oem_number: str = ""
    material: str = ""
    weight_grams: int = 0
    warranty: str = ""
    related: list["Product"] = Field(default_factory=list)


class Product(BaseModel):
    id: int
    name: str
    price: float
    original_price: float = 0
    discount_percent: float = 0
    description: str
    category: str
    part_category: str = ""
    brand: str = ""
    manufacturer_country: str = ""
    compatible_vehicles: list[str] = []
    colors: list[str]
    sizes: list[str]
    images: list[str]
    specs: dict[str, str] = {}
    popularity: int
    views: int = 0
    rating: float = 0
    review_count: int = 0
    stock_quantity: int = 0
    created_at: str
    is_new: bool
    in_stock: bool


class ProductCreate(BaseModel):
    name: str
    price: float
    original_price: float = 0
    discount_percent: float = 0
    description: str
    category: str
    part_category: str = ""
    brand: str = ""
    manufacturer_country: str = ""
    compatible_vehicles: list[str] = []
    colors: list[str] = []
    sizes: list[str] = ["استاندارد"]
    images: list[str] = []
    specs: dict[str, str] = {}
    popularity: int = 0
    views: int = 0
    rating: float = 0
    review_count: int = 0
    stock_quantity: int = 0
    is_new: bool = False
    in_stock: bool = True


class ProductUpdate(BaseModel):
    name: Optional[str] = None
    price: Optional[float] = None
    original_price: Optional[float] = None
    discount_percent: Optional[float] = None
    description: Optional[str] = None
    category: Optional[str] = None
    part_category: Optional[str] = None
    brand: Optional[str] = None
    manufacturer_country: Optional[str] = None
    compatible_vehicles: Optional[list[str]] = None
    colors: Optional[list[str]] = None
    sizes: Optional[list[str]] = None
    images: Optional[list[str]] = None
    specs: Optional[dict[str, str]] = None
    popularity: Optional[int] = None
    views: Optional[int] = None
    rating: Optional[float] = None
    review_count: Optional[int] = None
    stock_quantity: Optional[int] = None
    is_new: Optional[bool] = None
    in_stock: Optional[bool] = None


class UserPublic(BaseModel):
    id: int
    phone: str
    email: Optional[str] = None
    full_name: str
    role: str


class RegisterSendOtpRequest(BaseModel):
    phone: str
    password: str = Field(min_length=6)
    full_name: str
    email: Optional[str] = None


class VerifyOtpRequest(BaseModel):
    phone: str
    code: str


class LoginRequest(BaseModel):
    phone: str
    password: str


class ForgotPasswordSendOtpRequest(BaseModel):
    phone: str


class ResetPasswordRequest(BaseModel):
    phone: str
    code: str
    new_password: str = Field(min_length=6)


class ProfileUpdateRequest(BaseModel):
    full_name: Optional[str] = None
    email: Optional[str] = None


class AddressCreate(BaseModel):
    label: str = "خانه"
    address: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    first_name: str = ""
    last_name: str = ""
    city: str = ""
    state: str = ""
    zip_code: str = ""
    country: str = "ایران"
    is_default: bool = False


class AddressUpdate(BaseModel):
    label: Optional[str] = None
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    zip_code: Optional[str] = None
    country: Optional[str] = None
    is_default: Optional[bool] = None


class AddressOut(BaseModel):
    id: int
    label: str
    first_name: str
    last_name: str
    address: str
    city: str
    state: str
    zip_code: str
    country: str
    is_default: bool
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class DiscountValidateRequest(BaseModel):
    code: str
    subtotal: float


class DiscountValidateResponse(BaseModel):
    valid: bool
    code: str
    discount_amount: float
    message: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserPublic


class OtpSentResponse(BaseModel):
    message: str
    phone: str
    dev_otp: Optional[str] = None


class CartItem(BaseModel):
    product_id: int
    quantity: int
    color: str
    size: str


class CheckoutRequest(BaseModel):
    first_name: str = ""
    last_name: str = ""
    address: str = ""
    city: str = ""
    state: str = ""
    zip_code: str = ""
    country: str = "ایران"
    shipping_method: str = "post"
    discount_code: Optional[str] = None
    saved_address_id: Optional[int] = None
    card_number: str = ""
    expiry: str = ""
    cvv: str = ""
    items: list[CartItem]


class OrderItemOut(BaseModel):
    id: int
    product_id: int
    product_name: str
    quantity: int
    color: str
    size: str
    unit_price: float
    line_total: float


class OrderOut(BaseModel):
    id: int
    order_number: str
    user_id: int
    user_name: str
    user_phone: str
    user_email: Optional[str] = None
    status: str
    status_label: str
    subtotal: float
    discount_code: Optional[str] = None
    discount_amount: float
    shipping_method: str
    shipping_cost: float
    total: float
    phone: str
    first_name: str
    last_name: str
    address: str
    city: str
    state: str
    zip_code: str
    country: str
    created_at: str
    updated_at: str
    items: list[OrderItemOut]


class OrderStatusUpdate(BaseModel):
    status: str


class CheckoutResponse(BaseModel):
    order_id: str
    message: str
    subtotal: float
    discount_amount: float
    shipping_cost: float
    total: float


class TicketCreate(BaseModel):
    order_id: int
    subject: str
    message: str


class TicketMessageCreate(BaseModel):
    message: str


class TicketMessageOut(BaseModel):
    id: int
    user_id: int
    user_name: str
    message: str
    is_admin: bool
    created_at: str


class TicketOut(BaseModel):
    id: int
    order_id: int
    order_number: str
    user_id: int
    user_name: str
    subject: str
    status: str
    created_at: str
    updated_at: str
    messages: list[TicketMessageOut] = []


class MonthlyRevenue(BaseModel):
    year: int
    month: int
    month_label: str
    order_count: int
    revenue: float


class RevenueSummary(BaseModel):
    months: list[MonthlyRevenue]
    total_revenue: float
    total_orders: int


CatalogHotspotProduct.model_rebuild()
