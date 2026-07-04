import json
import sqlite3
from datetime import datetime, timedelta
from pathlib import Path

import bcrypt

from constants import OrderStatus

DB_PATH = Path(__file__).parent / "shop.db"
SCHEMA_VERSION = 8


def hash_password(plain: str) -> str:
    return bcrypt.hashpw(plain.encode(), bcrypt.gensalt()).decode()


def verify_password(plain: str, hashed: str) -> bool:
    return bcrypt.checkpw(plain.encode(), hashed.encode())



def get_conn() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def init_db() -> None:
    conn = get_conn()
    cur = conn.cursor()
    cur.executescript(
        """
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            full_name TEXT NOT NULL,
            role TEXT NOT NULL DEFAULT 'user',
            created_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            price REAL NOT NULL,
            description TEXT NOT NULL,
            category TEXT NOT NULL,
            colors TEXT NOT NULL,
            sizes TEXT NOT NULL,
            images TEXT NOT NULL,
            popularity INTEGER NOT NULL DEFAULT 0,
            is_new INTEGER NOT NULL DEFAULT 0,
            in_stock INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_number TEXT UNIQUE NOT NULL,
            user_id INTEGER NOT NULL,
            status TEXT NOT NULL DEFAULT 'registered',
            total REAL NOT NULL,
            email TEXT NOT NULL,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            address TEXT NOT NULL,
            city TEXT NOT NULL,
            state TEXT NOT NULL,
            zip_code TEXT NOT NULL,
            country TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id)
        );

        CREATE TABLE IF NOT EXISTS order_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_id INTEGER NOT NULL,
            product_id INTEGER NOT NULL,
            product_name TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            color TEXT NOT NULL,
            size TEXT NOT NULL,
            unit_price REAL NOT NULL,
            FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
            FOREIGN KEY (product_id) REFERENCES products(id)
        );

        CREATE TABLE IF NOT EXISTS tickets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            subject TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'open',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (order_id) REFERENCES orders(id),
            FOREIGN KEY (user_id) REFERENCES users(id)
        );

        CREATE TABLE IF NOT EXISTS ticket_messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ticket_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            message TEXT NOT NULL,
            is_admin INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE,
            FOREIGN KEY (user_id) REFERENCES users(id)
        );

        CREATE TABLE IF NOT EXISTS schema_meta (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS otp_codes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            phone TEXT NOT NULL,
            code TEXT NOT NULL,
            purpose TEXT NOT NULL,
            payload TEXT NOT NULL DEFAULT '',
            expires_at TEXT NOT NULL,
            created_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS user_addresses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            label TEXT NOT NULL DEFAULT 'خانه',
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            address TEXT NOT NULL,
            city TEXT NOT NULL,
            state TEXT NOT NULL,
            zip_code TEXT NOT NULL,
            country TEXT NOT NULL DEFAULT 'ایران',
            is_default INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS discount_codes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT UNIQUE NOT NULL,
            discount_type TEXT NOT NULL,
            value REAL NOT NULL,
            min_order REAL NOT NULL DEFAULT 0,
            active INTEGER NOT NULL DEFAULT 1,
            max_uses INTEGER,
            used_count INTEGER NOT NULL DEFAULT 0
        );
        """
    )
    conn.commit()
    _migrate_schema(cur)
    conn.commit()

    user_count = cur.execute("SELECT COUNT(*) FROM users").fetchone()[0]
    if user_count == 0:
        _seed_users(cur)
    product_count = cur.execute("SELECT COUNT(*) FROM products").fetchone()[0]
    if product_count == 0:
        _seed_products(cur)
    discount_count = cur.execute("SELECT COUNT(*) FROM discount_codes").fetchone()[0]
    if discount_count == 0:
        _seed_discounts(cur)
    conn.commit()
    conn.close()


def _table_columns(cur: sqlite3.Cursor, table: str) -> set[str]:
    cur.execute(f"PRAGMA table_info({table})")
    return {row[1] for row in cur.fetchall()}


def _migrate_schema(cur: sqlite3.Cursor) -> None:
    version_row = cur.execute("SELECT value FROM schema_meta WHERE key = 'version'").fetchone()
    version = int(version_row[0]) if version_row else 1

    user_cols = _table_columns(cur, "users")
    if "phone" not in user_cols:
        cur.execute("ALTER TABLE users ADD COLUMN phone TEXT")
    if "phone_verified" not in user_cols:
        cur.execute("ALTER TABLE users ADD COLUMN phone_verified INTEGER NOT NULL DEFAULT 1")

    order_cols = _table_columns(cur, "orders")
    for col, typedef in [
        ("phone", "TEXT"),
        ("shipping_method", "TEXT NOT NULL DEFAULT 'post'"),
        ("discount_code", "TEXT"),
        ("discount_amount", "REAL NOT NULL DEFAULT 0"),
        ("subtotal", "REAL NOT NULL DEFAULT 0"),
        ("shipping_cost", "REAL NOT NULL DEFAULT 0"),
        ("saved_address_id", "INTEGER"),
    ]:
        if col not in order_cols:
            cur.execute(f"ALTER TABLE orders ADD COLUMN {col} {typedef}")

    cur.execute(
        "UPDATE users SET phone = '09120000000', phone_verified = 1 WHERE role = 'admin' AND (phone IS NULL OR phone = '')"
    )
    cur.execute(
        "UPDATE users SET phone = '09121111111', phone_verified = 1 WHERE role = 'user' AND (phone IS NULL OR phone = '')"
    )
    cur.execute(
        "INSERT OR REPLACE INTO schema_meta (key, value) VALUES ('version', ?)",
        (str(SCHEMA_VERSION),),
    )
    _migrate_product_columns(cur)
    _migrate_users_email_nullable(cur)
    _maybe_reseed_products(cur)
    _migrate_catalog_tables(cur)
    _migrate_address_coords(cur)
    _migrate_order_status_legacy(cur)
    _migrate_catalog_vehicle_categories(cur)


def _migrate_catalog_vehicle_categories(cur: sqlite3.Cursor) -> None:
    if not _table_exists(cur, "catalog_vehicles"):
        return
    cols = _table_columns(cur, "catalog_vehicles")
    if "categories_json" not in cols:
        cur.execute("ALTER TABLE catalog_vehicles ADD COLUMN categories_json TEXT NOT NULL DEFAULT ''")


def _table_exists(cur: sqlite3.Cursor, name: str) -> bool:
    row = cur.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        (name,),
    ).fetchone()
    return row is not None


def _migrate_order_status_legacy(cur: sqlite3.Cursor) -> None:
    cur.execute("UPDATE orders SET status = 'delivered' WHERE status = 'completed'")
    cur.execute("UPDATE orders SET status = 'pending_payment' WHERE status = 'registered'")


def _migrate_address_coords(cur: sqlite3.Cursor) -> None:
    cols = _table_columns(cur, "user_addresses")
    if "latitude" not in cols:
        cur.execute("ALTER TABLE user_addresses ADD COLUMN latitude REAL")
    if "longitude" not in cols:
        cur.execute("ALTER TABLE user_addresses ADD COLUMN longitude REAL")


def _migrate_product_columns(cur: sqlite3.Cursor) -> None:
    product_cols = _table_columns(cur, "products")
    new_cols = [
        ("original_price", "REAL NOT NULL DEFAULT 0"),
        ("discount_percent", "REAL NOT NULL DEFAULT 0"),
        ("part_category", "TEXT NOT NULL DEFAULT ''"),
        ("brand", "TEXT NOT NULL DEFAULT ''"),
        ("manufacturer_country", "TEXT NOT NULL DEFAULT ''"),
        ("compatible_vehicles", "TEXT NOT NULL DEFAULT '[]'"),
        ("specs", "TEXT NOT NULL DEFAULT '{}'"),
        ("views", "INTEGER NOT NULL DEFAULT 0"),
        ("rating", "REAL NOT NULL DEFAULT 0"),
        ("review_count", "INTEGER NOT NULL DEFAULT 0"),
        ("stock_quantity", "INTEGER NOT NULL DEFAULT 0"),
    ]
    for col, typedef in new_cols:
        if col not in product_cols:
            cur.execute(f"ALTER TABLE products ADD COLUMN {col} {typedef}")


def _migrate_catalog_tables(cur: sqlite3.Cursor) -> None:
    from catalog_db import ensure_catalog_tables, seed_catalog_from_static

    ensure_catalog_tables(cur)
    seed_catalog_from_static(cur)


def _maybe_reseed_products(cur: sqlite3.Cursor) -> None:
    data_version = cur.execute(
        "SELECT value FROM schema_meta WHERE key = 'data_version'"
    ).fetchone()
    if data_version and data_version[0] == "jahan_giri_v1":
        return
    cur.execute("DELETE FROM order_items")
    cur.execute("DELETE FROM products")
    _seed_products(cur)
    cur.execute(
        "INSERT OR REPLACE INTO schema_meta (key, value) VALUES ('data_version', 'jahan_giri_v1')"
    )


def _migrate_users_email_nullable(cur: sqlite3.Cursor) -> None:
    cur.execute("PRAGMA table_info(users)")
    rows = cur.fetchall()
    email_row = next((r for r in rows if r[1] == "email"), None)
    if email_row is None or email_row[3] == 0:
        return

    cur.execute("PRAGMA foreign_keys=OFF")
    cur.executescript(
        """
        CREATE TABLE users_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            phone TEXT UNIQUE,
            email TEXT UNIQUE,
            password_hash TEXT NOT NULL,
            full_name TEXT NOT NULL,
            role TEXT NOT NULL DEFAULT 'user',
            phone_verified INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL
        );

        INSERT INTO users_new (id, phone, email, password_hash, full_name, role, phone_verified, created_at)
        SELECT id, phone, email, password_hash, full_name, role, phone_verified, created_at FROM users;

        DROP TABLE users;
        ALTER TABLE users_new RENAME TO users;
        """
    )
    cur.execute("PRAGMA foreign_keys=ON")


def _seed_discounts(cur: sqlite3.Cursor) -> None:
    codes = [
        ("WELCOME10", "percent", 10, 100000),
        ("MONAB50", "fixed", 50000, 200000),
        ("HANDCRAFT", "percent", 15, 500000),
    ]
    for code, dtype, value, min_order in codes:
        cur.execute(
            "INSERT INTO discount_codes (code, discount_type, value, min_order, active, used_count) VALUES (?, ?, ?, ?, 1, 0)",
            (code, dtype, value, min_order),
        )


def _seed_users(cur: sqlite3.Cursor) -> None:
    now = datetime.now().isoformat()
    cur.execute(
        """INSERT INTO users (phone, email, password_hash, full_name, role, phone_verified, created_at)
        VALUES (?, ?, ?, ?, ?, 1, ?)""",
        ("09120000000", "admin@jahangiri.ir", hash_password("admin123"), "مدیر جهانگیری", "admin", now),
    )
    cur.execute(
        """INSERT INTO users (phone, email, password_hash, full_name, role, phone_verified, created_at)
        VALUES (?, ?, ?, ?, ?, 1, ?)""",
        ("09121111111", None, hash_password("user123"), "کاربر نمونه", "user", now),
    )


def _seed_products(cur: sqlite3.Cursor) -> None:
    from data.seed_products import generate_products

    products = generate_products()
    for p in products:
        cur.execute(
            """INSERT INTO products
            (name, price, original_price, discount_percent, description, category, part_category,
             brand, manufacturer_country, compatible_vehicles, colors, sizes, images, specs,
             popularity, views, rating, review_count, stock_quantity, is_new, in_stock, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                p["name"],
                p["price"],
                p.get("original_price", p["price"]),
                p.get("discount_percent", 0),
                p["description"],
                p["category"],
                p.get("part_category", p["category"]),
                p.get("brand", ""),
                p.get("manufacturer_country", ""),
                json.dumps(p.get("compatible_vehicles", []), ensure_ascii=False),
                json.dumps(p["colors"], ensure_ascii=False),
                json.dumps(p["sizes"], ensure_ascii=False),
                json.dumps(p["images"], ensure_ascii=False),
                json.dumps(p.get("specs", {}), ensure_ascii=False),
                p["popularity"],
                p.get("views", 0),
                p.get("rating", 0),
                p.get("review_count", 0),
                p.get("stock_quantity", 0),
                int(p["is_new"]),
                int(p["in_stock"]),
                p["created_at"],
            ),
        )


def row_to_product(row: sqlite3.Row) -> dict:
    keys = row.keys()
    return {
        "id": row["id"],
        "name": row["name"],
        "price": row["price"],
        "original_price": row["original_price"] if "original_price" in keys else row["price"],
        "discount_percent": row["discount_percent"] if "discount_percent" in keys else 0,
        "description": row["description"],
        "category": row["category"],
        "part_category": row["part_category"] if "part_category" in keys else row["category"],
        "brand": row["brand"] if "brand" in keys else "",
        "manufacturer_country": row["manufacturer_country"] if "manufacturer_country" in keys else "",
        "compatible_vehicles": json.loads(row["compatible_vehicles"]) if "compatible_vehicles" in keys else [],
        "colors": json.loads(row["colors"]),
        "sizes": json.loads(row["sizes"]),
        "images": json.loads(row["images"]),
        "specs": json.loads(row["specs"]) if "specs" in keys else {},
        "popularity": row["popularity"],
        "views": row["views"] if "views" in keys else 0,
        "rating": row["rating"] if "rating" in keys else 0,
        "review_count": row["review_count"] if "review_count" in keys else 0,
        "stock_quantity": row["stock_quantity"] if "stock_quantity" in keys else 0,
        "created_at": row["created_at"],
        "is_new": bool(row["is_new"]),
        "in_stock": bool(row["in_stock"]),
    }

