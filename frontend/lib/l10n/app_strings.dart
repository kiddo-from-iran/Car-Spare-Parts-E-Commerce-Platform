import 'package:flutter/material.dart' show Icons;
import 'package:intl/intl.dart';

class AppStrings {
  // Brand
  static const appTitle = 'جهانگیری';
  static const brand = 'جهانگیری';
  static const brandTagline = 'قطعات یدکی اصل با بیش از ۵۰ سال سابقه';
  static const home = 'صفحه اصلی';
  static const categories = 'دسته‌بندی';
  static const shop = 'فروشگاه';
  static const smartCatalog = 'کاتالوگ هوشمند قطعات';
  static const about = 'درباره ما';
  static const contact = 'ارتباط با ما';
  static const loginRegister = 'ورود / ثبت‌نام';
  static const login = 'ورود';
  static const register = 'ثبت‌نام';
  static const logout = 'خروج';
  static const myOrders = 'سفارش‌های من';
  static const myTickets = 'تیکت‌های پشتیبانی';
  static const ticketsOnOrdersHint = 'تیکت پشتیبانی فقط برای سفارش‌های در جریان قابل ثبت است';
  static const mapPickHint = 'روی نقشه کلیک کنید تا محل دقیق آدرس مشخص شود';
  static const myWishlist = 'علاقه‌مندی‌ها';
  static const notifications = 'اعلان‌ها';
  static const adminPanel = 'پنل مدیریت';
  static const account = 'حساب کاربری';
  static const userDashboard = 'داشبورد';
  static const userProfile = 'پروفایل';
  static const viewAll = 'مشاهده همه';

  static const searchHint = 'جستجو در جهانگیری';
  static const searchProductsHint = 'جستجوی قطعات یدکی...';
  static const searchNoResults = 'محصولی یافت نشد';
  static const partnerBrandsTitle = 'برندهای همکار';
  static const footerWorkingHours = 'ساعات کاری';

  // Home
  static const heroSlides = [
    ('قطعات یدکی اصل', 'بیش از ۵۰ سال تجربه در فروش قطعات یدکی خودرو', 'https://picsum.photos/seed/hero1/1600/600'),
    ('ارسال سراسر ایران', 'ارسال سریع با پست پیشتاز به تمام نقاط کشور', 'https://picsum.photos/seed/hero2/1600/600'),
    ('ضمانت اصالت کالا', 'تضمین اصالت تمامی محصولات با گارانتی معتبر', 'https://picsum.photos/seed/hero3/1600/600'),
  ];
  static const carCategoriesTitle = 'دسته‌بندی خودرو';
  static const partCategoriesTitle = 'دسته‌بندی بر اساس قطعات';
  static const storeFeaturesTitle = 'چرا جهانگیری؟';
  static const exploreShop = 'مشاهده فروشگاه';

  static const features = [
    ('ارسال به سراسر ایران', 'با پست پیشتاز به تمام نقاط کشور', Icons.local_shipping_outlined),
    ('پرداخت اقساطی', 'امکان پرداخت اقساطی با اسنپ‌پی', Icons.credit_card_outlined),
    ('ضمانت اصالت کالا', 'تضمین اصالت تمامی محصولات', Icons.verified_outlined),
    ('پشتیبانی عالی', 'پشتیبانی حرفه‌ای و مشاوره فنی', Icons.support_agent_outlined),
  ];

  // Product
  static const newBadge = 'جدید';
  static const inStock = 'موجود';
  static const outOfStock = 'ناموجود';
  static String stockAvailable(int quantity) => '$quantity عدد موجود';
  static const stockInsufficient = 'موجودی کافی نیست';
  static const stockMaxInCart = 'به حداکثر موجودی این محصول رسیدید';
  static const quickView = 'مشاهده سریع';
  static const addToCart = 'افزودن به سبد';
  static const addToWishlist = 'علاقه‌مندی';
  static const compatibleVehicles = 'خودروهای سازگار';
  static const manufacturer = 'سازنده';
  static const country = 'کشور سازنده';
  static const specifications = 'مشخصات فنی';
  static const reviews = 'نظرات مشتریان';
  static const relatedProducts = 'محصولات مرتبط';
  static const share = 'اشتراک‌گذاری';
  static const quantity = 'تعداد';
  static const productBrand = 'برند';

  // Shop
  static const filters = 'فیلترها';
  static const vehicleFilter = 'خودرو';
  static const partCategoryFilter = 'دسته قطعه';
  static const countryFilter = 'کشور سازنده';
  static const brandFilter = 'برند';
  static const priceRange = 'محدوده قیمت';
  static const availability = 'موجودی';
  static const available = 'موجود';
  static const unavailable = 'ناموجود';
  static const sortBy = 'مرتب‌سازی';
  static const sortNewest = 'جدیدترین';
  static const sortPopular = 'پرفروش‌ترین';
  static const sortViews = 'بیشترین بازدید';
  static const sortPriceAsc = 'ارزان‌ترین';
  static const sortPriceDesc = 'گران‌ترین';
  static const sortDiscount = 'تخفیف‌دار';
  static const applyFilters = 'اعمال فیلتر';
  static const clearAll = 'پاک کردن';
  static const noProducts = 'محصولی با این فیلترها یافت نشد.';

  // Cart & Checkout
  static const cartEmpty = 'سبد خرید شما خالی است';
  static const subtotal = 'جمع جزء';
  static const proceedToCheckout = 'تسویه حساب';
  static const checkout = 'تسویه حساب';
  static const continueShopping = 'ادامه خرید';
  static const orderSummary = 'خلاصه سفارش';
  static const total = 'مجموع';
  static const placeOrder = 'ثبت سفارش';
  static const discountCode = 'کد تخفیف';
  static const shippingCost = 'هزینه ارسال';
  static const discount = 'تخفیف';
  static const shippingMethod = 'روش ارسال';
  static const paymentMethod = 'روش پرداخت';

  // Auth
  static const password = 'رمز عبور';
  static const fullName = 'نام و نام خانوادگی';
  static const phone = 'شماره موبایل';
  static const email = 'ایمیل (اختیاری)';
  static const forgotPassword = 'فراموشی رمز عبور';
  static const myProfile = 'پروفایل من';
  static const myAddresses = 'آدرس‌های من';
  static const changePassword = 'تغییر رمز عبور';

  // Legacy / shared strings used across account & admin pages
  static const addAddress = 'افزودن آدرس';
  static const editAddress = 'ویرایش آدرس';
  static const deleteAddress = 'حذف آدرس';
  static const addressLabel = 'برچسب آدرس';
  static const defaultAddress = 'آدرس پیش‌فرض';
  static const firstName = 'نام';
  static const lastName = 'نام خانوادگی';
  static const address = 'آدرس';
  static const city = 'شهر';
  static const state = 'استان';
  static const zipCode = 'کد پستی';
  static const countryField = 'کشور';
  static const phoneReadonly = 'شماره موبایل (غیرقابل تغییر)';
  static const noAddresses = 'آدرسی ذخیره نشده است';
  static const noOrders = 'سفارشی یافت نشد';
  static const noTickets = 'تیکتی یافت نشد';
  static const orderStatus = 'وضعیت سفارش';
  static const orderDetails = 'جزئیات سفارش';
  static const orderNumber = 'شماره سفارش';
  static const openTicket = 'ثبت تیکت';
  static const ticketSubject = 'موضوع';
  static const ticketMessage = 'پیام';
  static const send = 'ارسال';
  static const reply = 'پاسخ';
  static const closeTicket = 'بستن تیکت';
  static const processing = 'در حال پردازش...';
  static const toastProfileSaved = 'پروفایل ذخیره شد';
  static const toastAddressSaved = 'آدرس ذخیره شد';
  static const toastAddressDeleted = 'آدرس حذف شد';
  static const toastLoginSuccess = 'با موفقیت وارد شدید';
  static const toastRegisterSuccess = 'ثبت‌نام با موفقیت انجام شد';
  static const toastLogoutSuccess = 'از حساب خارج شدید';
  static const toastOrderPlaced = 'سفارش شما با موفقیت ثبت شد';
  static const activeOrders = 'در حال اجرا';
  static const completedOrders = 'تکمیل‌شده';
  static const allOrders = 'همه';
  static const changeStatus = 'تغییر وضعیت';
  static const addProduct = 'افزودن محصول';
  static const editProduct = 'ویرایش محصول';
  static const deleteProduct = 'حذف محصول';
  static const confirmDelete = 'آیا از حذف این محصول مطمئن هستید؟';
  static const productName = 'نام محصول';
  static const price = 'قیمت';
  static const description = 'توضیحات';
  static const revenueTotal = 'مجموع درآمد';
  static const orderCount = 'تعداد سفارش';
  static const applyDiscount = 'اعمال';
  static const shippingPost = 'پست پیشتاز';
  static const shippingTipax = 'تیپاکس';
  static const thankYouOrder = 'از خرید شما سپاسگزاریم';
  static const checkoutFailed = 'خطا در پرداخت. لطفاً دوباره تلاش کنید.';
  static const browseProducts = 'مشاهده محصولات';
  static const paymentPlaceholder = 'پرداخت (نمایشی)';
  static const paymentNote = 'این یک فرآیند پرداخت نمایشی است.';
  static const cardNumber = 'شماره کارت';
  static const expiry = 'انقضا';
  static const cvv = 'CVV';
  static const required = 'الزامی';
  static const noAccount = 'حساب ندارید؟';
  static const haveAccount = 'قبلاً ثبت‌نام کرده‌اید؟';
  static const otpCode = 'کد تأیید';
  static const sendOtp = 'ارسال کد تأیید';
  static const verifyOtp = 'تأیید و ثبت‌نام';
  static const resetPassword = 'تغییر رمز عبور';
  static const backToLogin = 'بازگشت به ورود';
  static const loginRequired = 'برای ادامه لطفاً وارد شوید';
  static const size = 'سایز';
  static const color = 'رنگ';
  static const youMayAlsoLike = 'محصولات مرتبط';
  static const category = 'دسته‌بندی';
  static const allCategories = 'همه دسته‌ها';
  static const tracking = 'پیگیری سفارش';
  static const otpHint = 'کد تأیید در کنسول مرورگر نمایش داده می‌شود';
  static const discountApplied = 'تخفیف اعمال شد';
  static const toastPasswordChanged = 'رمز عبور با موفقیت تغییر کرد';
  static const shippingAddress = 'آدرس ارسال';
  static const newAddress = 'آدرس جدید';
  static const savedAddresses = 'آدرس‌های ذخیره‌شده';
  static const toastOtpSent = 'کد تأیید ارسال شد';

  static String addedToCart(String name) => '$name به سبد اضافه شد';
  static String orderSuccess(String orderId) => 'سفارش $orderId با موفقیت ثبت شد.';

  // Footer
  static const footerQuickAccess = 'دسترسی سریع';
  static const footerContact = 'تماس با ما';
  static const footerTrust = 'نماد اعتماد الکترونیکی';
  static const footerSocial = 'ارتباط با ما';
  static const footerShop = 'فروشگاه';
  static const footerSupport = 'پشتیبانی';
  static const footerCarCategories = 'دسته‌بندی بر اساس خودرو';
  static const footerPartCategories = 'دسته‌بندی بر اساس قطعات';
  static const storePhone = '۰۲۶-۳۴۵۶۷۸۹۰';
  static const supportPhone = '۰۹۱۲-۱۲۳۴۵۶۷';
  static const telegramId = '@jahangiri_parts';

  // About
  static const aboutTitle = 'درباره جهانگیری';
  static const aboutManagement = 'مدیریت جهانگیری';
  static const aboutHistory =
      'شرکت جهانگیری با بیش از ۵۰ سال سابقه فعالیت در زمینه فروش قطعات یدکی خودرو، '
      'یکی از معتبرترین فروشگاه‌های لوازم یدکی در استان البرز است. '
      'ما متعهد به ارائه محصولات اصل، مشاوره حرفه‌ای و رضایت مشتری هستیم.';
  static const aboutAddress = 'باغستان، کرج، استان البرز';

  // Contact
  static const contactTitle = 'ارتباط با ما';
  static const sendMessage = 'ارسال پیام';
  static const name = 'نام';
  static const message = 'پیام';

  // Admin
  static const adminDashboard = 'داشبورد';
  static const adminOrders = 'مدیریت سفارش‌ها';
  static const adminProducts = 'مدیریت محصولات';
  static const adminInventory = 'مدیریت موجودی';
  static const adminCategories = 'دسته‌بندی‌ها';
  static const adminCustomers = 'مشتریان';
  static const adminTickets = 'تیکت‌ها';
  static const adminDiscounts = 'تخفیف‌ها';
  static const adminReports = 'گزارش‌ها';
  static const adminSettings = 'تنظیمات';
  static const adminRevenue = 'گزارش فروش';
  static const adminCatalogs = 'کاتالوگ هوشمند';
  static const addCatalog = 'افزودن کاتالوگ';
  static const editCatalog = 'ویرایش کاتالوگ';
  static const catalogHotspots = 'نقاط روی تصویر';
  static const catalogHotspotLabel = 'عنوان نقطه';
  static const catalogAssignProducts = 'محصولات مرتبط';
  static const catalogUploadImage = 'بارگذاری تصویر';
  static const catalogAddView = 'افزودن نما';
  static const catalogClickToPlace = 'روی تصویر کلیک کنید تا نقطه اضافه شود';
  static const catalogAddCategory = 'افزودن دسته';
  static const catalogCategoryName = 'نام دسته';
  static const save = 'ذخیره';
  static const cancel = 'انصراف';

  static const loadError = 'خطا در بارگذاری. لطفاً اتصال به سرور را بررسی کنید.';
  static const productNotFound = 'محصول یافت نشد';
  static const backToShop = 'بازگشت به فروشگاه';

  // Smart catalog
  static const smartCatalogTitle = 'کاتالوگ هوشمند قطعات';
  static const smartCatalogSubtitle = 'قطعه مورد نظر را روی نقشه خودرو پیدا کنید و اطلاعات کامل آن را ببینید';
  static const selectVehicle = 'انتخاب خودرو';
  static const catalogSearchHint = 'جستجو: نام قطعه، کد OEM، شماره فنی...';
  static const catalogClickHint = 'روی نقاط مشخص‌شده کلیک کنید تا اطلاعات قطعه نمایش داده شود';
  static const catalogCategoriesTitle = 'دسته‌بندی قطعات این خودرو';
  static const catalogAllCategories = 'همه';
  static const catalogViewPlaceholder = 'تصویر این نما هنوز اضافه نشده است';
  static const partNumber = 'شماره فنی';
  static const oemNumber = 'شماره OEM';
  static const material = 'جنس';
  static const weight = 'وزن';
  static const warranty = 'گارانتی';
  static const viewProduct = 'مشاهده محصول';
  static const compare = 'مقایسه';
  static const grams = 'گرم';

  static String productCount(int count) => '$count محصول';
  static String cartTitle(int count) => 'سبد خرید ($count)';
  static String pageOf(int page, int total) => 'صفحه $page از $total';
  static String formatPrice(double price) {
    final formatted = NumberFormat('#,##0', 'fa_IR').format(price);
    return '$formatted تومان';
  }
  static String formatPriceRange(double min, double max) =>
      '${formatPrice(min)} تا ${formatPrice(max)}';
  static String copyright(int year) => '© $year جهانگیری. تمامی حقوق محفوظ است.';
}
