import sqlite3
import json
import base64
import hmac
import hashlib
import os
from fastapi import FastAPI, HTTPException, Request, Depends, File, UploadFile, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from typing import Optional, List

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

os.makedirs("uploads", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

DB_FILE = "unitrade.db"
SECRET_KEY = "unitrade_super_secret"

def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()

def create_jwt(payload: dict) -> str:
    header = base64.urlsafe_b64encode(json.dumps({"alg": "HS256", "typ": "JWT"}).encode()).decode().rstrip('=')
    payload_b64 = base64.urlsafe_b64encode(json.dumps(payload).encode()).decode().rstrip('=')
    signature = hmac.new(SECRET_KEY.encode(), f"{header}.{payload_b64}".encode(), hashlib.sha256).digest()
    signature_b64 = base64.urlsafe_b64encode(signature).decode().rstrip('=')
    return f"{header}.{payload_b64}.{signature_b64}"

def verify_jwt(token: str) -> dict:
    try:
        parts = token.split('.')
        if len(parts) != 3:
            return None
        signature = hmac.new(SECRET_KEY.encode(), f"{parts[0]}.{parts[1]}".encode(), hashlib.sha256).digest()
        expected_signature_b64 = base64.urlsafe_b64encode(signature).decode().rstrip('=')
        if parts[2] != expected_signature_b64:
            return None
        payload_pad = parts[1] + "=" * ((4 - len(parts[1]) % 4) % 4)
        payload_json = base64.urlsafe_b64decode(payload_pad).decode()
        return json.loads(payload_json)
    except Exception:
        return None

def get_current_user(request: Request):
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Unauthorized")
    token = auth_header.split(" ")[1]
    payload = verify_jwt(token)
    if not payload:
        raise HTTPException(status_code=401, detail="Invalid token")
    return payload

def init_db():
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT UNIQUE,
            password_hash TEXT,
            campus TEXT,
            points INTEGER DEFAULT 0,
            role TEXT DEFAULT 'STUDENT',
            verification_status TEXT DEFAULT 'PENDING',
            student_id TEXT
        )
    ''')
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            seller_id INTEGER,
            name TEXT,
            description TEXT,
            price INTEGER,
            category TEXT,
            condition TEXT,
            campus TEXT,
            tags TEXT,
            image_url TEXT,
            stock INTEGER DEFAULT 1
        )
    ''')
    
    # Auto-migrate: Add new columns if they don't exist
    try:
        cursor.execute("ALTER TABLE users ADD COLUMN points INTEGER DEFAULT 0")
    except sqlite3.OperationalError:
        pass

    try:
        cursor.execute("ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'STUDENT'")
    except sqlite3.OperationalError:
        pass

    try:
        cursor.execute("ALTER TABLE users ADD COLUMN verification_status TEXT DEFAULT 'APPROVED'")
    except sqlite3.OperationalError:
        pass

    try:
        cursor.execute("ALTER TABLE users ADD COLUMN student_id TEXT")
    except sqlite3.OperationalError:
        pass

    try:
        cursor.execute("ALTER TABLE products ADD COLUMN item_type TEXT DEFAULT 'Barang'")
    except sqlite3.OperationalError:
        pass
        
    try:
        cursor.execute("ALTER TABLE products ADD COLUMN advanced_details TEXT DEFAULT '{}'")
    except sqlite3.OperationalError:
        pass
        
    try:
        cursor.execute("ALTER TABLE products ADD COLUMN approval_status TEXT DEFAULT 'APPROVED'")
    except sqlite3.OperationalError:
        pass

    try:
        cursor.execute("ALTER TABLE products ADD COLUMN stock INTEGER DEFAULT 1")
    except sqlite3.OperationalError:
        pass


    cursor.execute('''
        CREATE TABLE IF NOT EXISTS services (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            seller_id INTEGER,
            title TEXT,
            description TEXT,
            category TEXT,
            price INTEGER,
            max_price INTEGER,
            campus TEXT,
            meetup_location TEXT,
            image_url TEXT,
            approval_status TEXT DEFAULT 'PENDING',
            FOREIGN KEY(seller_id) REFERENCES users(id)
        )
    ''')
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS carts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            product_id INTEGER,
            quantity INTEGER DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(user_id) REFERENCES users(id),
            FOREIGN KEY(product_id) REFERENCES products(id)
        )
    ''')
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            total_amount INTEGER,
            payment_method TEXT,
            delivery_address TEXT,
            status TEXT DEFAULT 'Pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(user_id) REFERENCES users(id)
        )
    ''')
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS order_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_id INTEGER,
            product_id INTEGER,
            quantity INTEGER,
            price_at_checkout INTEGER,
            FOREIGN KEY(order_id) REFERENCES orders(id),
            FOREIGN KEY(product_id) REFERENCES products(id)
        )
    ''')
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS wishlists (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            product_id INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(user_id) REFERENCES users(id),
            FOREIGN KEY(product_id) REFERENCES products(id),
            UNIQUE(user_id, product_id)
        )
    ''')
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS reviews (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            reviewer_id INTEGER,
            product_id INTEGER,
            service_id INTEGER,
            rating INTEGER,
            comment TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(reviewer_id) REFERENCES users(id),
            FOREIGN KEY(product_id) REFERENCES products(id),
            FOREIGN KEY(service_id) REFERENCES services(id)
        )
    ''')
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sender_id INTEGER,
            receiver_id INTEGER,
            product_id INTEGER,
            message TEXT,
            is_read BOOLEAN DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(sender_id) REFERENCES users(id),
            FOREIGN KEY(receiver_id) REFERENCES users(id),
            FOREIGN KEY(product_id) REFERENCES products(id)
        )
    ''')
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS notifications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            title TEXT,
            message TEXT,
            is_read BOOLEAN DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(user_id) REFERENCES users(id)
        )
    ''')
    
    # Try to add is_read column to messages if it doesn't exist
    try:
        cursor.execute("ALTER TABLE messages ADD COLUMN is_read BOOLEAN DEFAULT 0")
    except sqlite3.OperationalError:
        pass
    
    # Check if empty to seed data
    cursor.execute("SELECT COUNT(*) FROM users")
    if cursor.fetchone()[0] == 0:
        cursor.execute("INSERT INTO users (name, email, password_hash, campus, points, verification_status, role) VALUES (?, ?, ?, ?, ?, ?, ?)", 
            ("Admin User", "admin@unitrade.ac.id", hash_password("admin123"), "Universitas Nasional - Jakarta Selatan, Pasar Minggu", 100, "APPROVED", "ADMIN"))
            
        cursor.execute("INSERT INTO users (name, email, password_hash, campus, points, verification_status, role) VALUES (?, ?, ?, ?, ?, ?, ?)", 
            ("Tester Student", "tester@student.ac.id", hash_password("123456"), "Universitas Nasional - Jakarta Selatan, Pasar Minggu", 100, "APPROVED", "STUDENT"))
        user_id = cursor.lastrowid
        
        dummy_products = [
            (user_id, "MacBook Pro M1 2020 8/256GB", "Lancar jaya untuk ngoding, lecet pemakaian sedikit.", 12000000, "Elektronik", "Pemakaian Wajar (Fair/Used)", "Universitas Nasional - Jakarta Selatan, Pasar Minggu", json.dumps(["DORM ESSENTIALS", "GOOD"]), "", "APPROVED"),
            (user_id, "Sony WH-1000XM4 Headphones", "Headphones over-ear Active Noise Cancelling terbaik. Kondisi istimewa, lengkap dengan kotak.", 2700000, "Elektronik", "Mulus (Like New)", "Universitas Nasional - Jakarta Selatan, Pasar Minggu", json.dumps(["PHONES", "LIKE NEW"]), "", "APPROVED"),
            (user_id, "Jaket Hoodie Teknik Sipil 2023", "Hoodie tebal warna biru dongker. Belum pernah dipakai.", 150000, "Pakaian", "Baru (Brand New)", "Universitas Indonesia - Depok, Beji", json.dumps(["CLOTHING", "NEW"]), "", "APPROVED")
        ]
        cursor.executemany("INSERT INTO products (seller_id, name, description, price, category, condition, campus, tags, image_url, approval_status, stock) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)", dummy_products)
        
        dummy_services = [
            (user_id, "Jasa Rakit PC / Install Ulang Laptop", "Menerima jasa rakit PC rapi, install Windows, Linux.", "IT Support", 100000, 250000, "Universitas Nasional - Jakarta Selatan, Pasar Minggu", "Lab Komputer Blok A", "", "APPROVED"),
            (user_id, "Jasa Desain Poster / UI UX", "Bisa desain pakai Figma atau Canva.", "Desain", 50000, None, "Universitas Nasional - Jakarta Selatan, Pasar Minggu", "Kantin Bawah", "", "APPROVED")
        ]
        cursor.executemany("INSERT INTO services (seller_id, title, description, category, price, max_price, campus, meetup_location, image_url, approval_status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", dummy_services)
        
        dummy_notifications = [
            (user_id, "Welcome to UniTrade!", "Selamat datang di UniTrade! Temukan barang dan jasa dari teman kampusmu di sini.", 0),
            (user_id, "Tips Berjualan", "Lengkapi profil dan foto barang jualanmu agar lebih menarik pembeli ya!", 0)
        ]
        cursor.executemany("INSERT INTO notifications (user_id, title, message, is_read) VALUES (?, ?, ?, ?)", dummy_notifications)
        conn.commit()
    conn.close()

# Initialize DB on startup
init_db()

class RegisterRequest(BaseModel):
    name: str
    email: str
    password: str
    campus: str

class LoginRequest(BaseModel):
    email: str
    password: str

class ProductCreate(BaseModel):
    name: str
    description: str
    price: int
    category: str
    condition: str
    campus: str
    tags: List[str]

class MessageCreate(BaseModel):
    receiver_id: int
    product_id: int
    message: str

class CartItemCreate(BaseModel):
    product_id: int
    quantity: int = 1

class CartItemUpdate(BaseModel):
    quantity: int

class CheckoutRequest(BaseModel):
    payment_method: str
    delivery_address: str

@app.post("/register")
async def register(request: RegisterRequest):
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    try:
        cursor.execute("INSERT INTO users (name, email, password_hash, campus, verification_status, role, points) VALUES (?, ?, ?, ?, ?, ?, ?)", 
            (request.name, request.email, hash_password(request.password), request.campus, 'APPROVED', 'STUDENT', 100))
        conn.commit()
        return {"message": "User registered successfully"}
    except sqlite3.IntegrityError:
        raise HTTPException(status_code=400, detail="Email already registered")
    finally:
        conn.close()

@app.post("/login")
async def login(request: LoginRequest):
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users WHERE email = ? AND password_hash = ?", (request.email, hash_password(request.password)))
    user = cursor.fetchone()
    conn.close()
    
    if user:
        if user["verification_status"] == "PENDING":
            raise HTTPException(status_code=403, detail="Account pending approval by admin")
        
        token = create_jwt({"user_id": user["id"], "name": user["name"], "campus": user["campus"], "role": user["role"]})
        return {
            "message": "Login berhasil!", 
            "token": token,
            "user": {"id": user["id"], "name": user["name"], "email": user["email"], "campus": user["campus"], "role": user["role"]}
        }
    else:
        raise HTTPException(status_code=401, detail="Email atau password salah")

@app.get("/products")
async def get_products(
    q: Optional[str] = None,
    category: Optional[str] = None,
    condition: Optional[str] = None,
    min_price: Optional[int] = None,
    max_price: Optional[int] = None,
    campus: Optional[str] = None
):
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    query = """
        SELECT * FROM (
            SELECT p.id, p.seller_id, u.name as seller_name, u.campus as seller_campus,
                   p.name, p.description, p.price, p.category, p.condition, p.campus,
                   p.tags, p.image_url, p.item_type, p.advanced_details
            FROM products p
            JOIN users u ON p.seller_id = u.id
            WHERE p.approval_status = 'APPROVED'
            
            UNION ALL
            
            SELECT s.id, s.seller_id, u.name as seller_name, u.campus as seller_campus,
                   s.title as name, s.description, s.price, s.category, 'Jasa' as condition, s.campus,
                   '["JASA"]' as tags, s.image_url, 'Jasa' as item_type, 
                   '{"max_price": "' || IFNULL(s.max_price, '') || '", "meetup_location": "' || IFNULL(s.meetup_location, '') || '"}' as advanced_details
            FROM services s
            JOIN users u ON s.seller_id = u.id
            WHERE s.approval_status = 'APPROVED'
        ) p
        WHERE 1=1
    """
    params = []

    if q and q.strip():
        query += " AND (p.name LIKE ? OR p.description LIKE ?)"
        params.extend([f"%{q}%", f"%{q}%"])
    
    if category and category not in ["All", "Semua Kategori"]:
        if category == "Jasa":
            query += " AND (p.category = ? OR p.item_type = ?)"
            params.extend([category, category])
        else:
            query += " AND p.category = ?"
            params.append(category)
        
    if condition and condition not in ["Any Condition", "Semua Kondisi"]:
        query += " AND p.condition = ?"
        params.append(condition)
        
    if min_price is not None:
        query += " AND p.price >= ?"
        params.append(min_price)
        
    if max_price is not None:
        query += " AND p.price <= ?"
        params.append(max_price)
        
    if campus:
        query += " AND p.campus = ?"
        params.append(campus)

    # Order by id DESC. Since ids overlap, it's roughly interleaving them.
    query += " ORDER BY p.id DESC"

    cursor.execute(query, params)
    rows = cursor.fetchall()
    conn.close()

    results = []
    for row in rows:
        product_dict = {
            "id": row["id"],
            "seller_id": row["seller_id"],
            "seller_name": row["seller_name"],
            "seller_campus": row["seller_campus"],
            "name": row["name"],
            "description": row["description"],
            "price": row["price"],
            "category": row["category"],
            "condition": row["condition"],
            "campus": row["campus"],
            "tags": json.loads(row["tags"]) if row["tags"] else [],
            "image_url": row["image_url"],
            "item_type": row["item_type"] if "item_type" in row.keys() else "Barang",
            "advanced_details": {}
        }
        if "advanced_details" in row.keys() and row["advanced_details"]:
            try:
                product_dict["advanced_details"] = json.loads(row["advanced_details"])
            except Exception:
                pass
        results.append(product_dict)

    return results

@app.get("/campuses")
async def get_campuses():
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute("SELECT DISTINCT campus FROM users WHERE campus IS NOT NULL AND campus != ''")
    rows = cursor.fetchall()
    conn.close()
    return [row["campus"] for row in rows]

@app.post("/products")
async def create_product(
    request: Request,
    name: str = Form(...),
    description: str = Form(...),
    price: int = Form(...),
    category: str = Form(...),
    condition: str = Form(...),
    campus: str = Form(...),
    tags: str = Form(...),
    item_type: str = Form("Barang"),
    advanced_details: str = Form("{}"),
    file: Optional[UploadFile] = File(None)
):
    current_user = get_current_user(request)
    
    image_url = ""
    if file and file.filename:
        file_path = f"uploads/{file.filename}"
        with open(file_path, "wb") as f:
            f.write(await file.read())
        image_url = f"/uploads/{file.filename}"
        
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO products (seller_id, name, description, price, category, condition, campus, tags, image_url, item_type, advanced_details, approval_status) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'PENDING')
    ''', (current_user["user_id"], name, description, price, category, condition, campus, tags, image_url, item_type, advanced_details))
    conn.commit()
    new_id = cursor.lastrowid
    conn.close()
    return {"message": "Product created successfully", "product_id": new_id}

@app.put("/products/{product_id}")
async def update_product(
    product_id: int,
    request: Request,
    name: str = Form(...),
    description: str = Form(...),
    price: int = Form(...),
    category: str = Form(...),
    condition: str = Form(...),
    campus: str = Form(...),
    tags: str = Form(...),
    item_type: str = Form("Barang"),
    advanced_details: str = Form("{}"),
    file: Optional[UploadFile] = File(None)
):
    current_user = get_current_user(request)
    
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    cursor.execute("SELECT * FROM products WHERE id = ?", (product_id,))
    product = cursor.fetchone()
    
    if not product:
        conn.close()
        raise HTTPException(status_code=404, detail="Produk tidak ditemukan")
        
    if product["seller_id"] != current_user["user_id"]:
        conn.close()
        raise HTTPException(status_code=403, detail="Anda tidak berhak mengedit produk ini")
        
    image_url = product["image_url"]
    if file and file.filename:
        file_path = f"uploads/{file.filename}"
        with open(file_path, "wb") as f:
            f.write(await file.read())
        image_url = f"/uploads/{file.filename}"
        
    cursor.execute('''
        UPDATE products 
        SET name=?, description=?, price=?, category=?, condition=?, campus=?, tags=?, image_url=?, item_type=?, advanced_details=?
        WHERE id=?
    ''', (name, description, price, category, condition, campus, tags, image_url, item_type, advanced_details, product_id))
    
    conn.commit()
    conn.close()
    return {"message": "Product updated successfully"}

# Socket.io setup for chat

@app.post("/messages")
async def send_message(request: Request, msg: MessageCreate):
    current_user = get_current_user(request)
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("INSERT INTO messages (sender_id, receiver_id, product_id, message) VALUES (?, ?, ?, ?)",
        (current_user["user_id"], msg.receiver_id, msg.product_id, msg.message))
        
    # Notifikasi pesan baru
    cursor.execute(
        "INSERT INTO notifications (user_id, title, message) VALUES (?, ?, ?)",
        (msg.receiver_id, "Pesan Baru", f"Anda mendapat pesan baru.")
    )
    conn.commit()
    conn.close()
    return {"status": "success"}

@app.get("/chat/unread_count")
async def get_chat_unread_count(request: Request):
    current_user = get_current_user(request)
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute('''
        SELECT COUNT(*) FROM messages 
        WHERE receiver_id = ? AND is_read = 0
    ''', (current_user["user_id"],))
    count = cursor.fetchone()[0]
    conn.close()
    return {"unread_count": count}

@app.post("/chat/{other_user_id}/read")
async def mark_chat_read(request: Request, other_user_id: int):
    current_user = get_current_user(request)
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute('''
        UPDATE messages SET is_read = 1 
        WHERE receiver_id = ? AND sender_id = ?
    ''', (current_user["user_id"], other_user_id))
    conn.commit()
    conn.close()
    return {"status": "success"}

@app.get("/chats")
async def get_chats(request: Request):
    current_user = get_current_user(request)
    uid = current_user["user_id"]
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute('''
        SELECT 
            m.product_id, 
            p.name as product_name,
            CASE WHEN m.sender_id = ? THEN m.receiver_id ELSE m.sender_id END as other_user_id,
            u.name as other_user_name,
            MAX(m.created_at) as last_message_time,
            m.message as last_message
        FROM messages m
        JOIN users u ON u.id = CASE WHEN m.sender_id = ? THEN m.receiver_id ELSE m.sender_id END
        JOIN products p ON p.id = m.product_id
        WHERE m.sender_id = ? OR m.receiver_id = ?
        GROUP BY m.product_id, CASE WHEN m.sender_id = ? THEN m.receiver_id ELSE m.sender_id END
        ORDER BY last_message_time DESC
    ''', (uid, uid, uid, uid, uid))
    chats = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return chats

@app.get("/chats/{other_user_id}/{product_id}")
async def get_chat_history(request: Request, other_user_id: int, product_id: int):
    current_user = get_current_user(request)
    uid = current_user["user_id"]
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute('''
        SELECT sender_id, receiver_id, message, created_at 
        FROM messages 
        WHERE product_id = ? 
        AND ((sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?))
        ORDER BY created_at ASC
    ''', (product_id, uid, other_user_id, other_user_id, uid))
    messages = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return messages
# NEW ENDPOINTS ADDED FOR WEB MIGRATION
class ServiceCreate(BaseModel):
    title: str
    description: str
    category: str
    price: int
    max_price: Optional[int] = None

@app.get("/services")
async def get_services(
    request: Request,
    q: Optional[str] = None,
    category: Optional[str] = None,
    min_price: Optional[int] = None,
    max_price: Optional[int] = None,
    campus: Optional[str] = None
):
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    query = """
        SELECT s.*, u.name as seller_name, u.campus as seller_campus 
        FROM services s 
        JOIN users u ON s.seller_id = u.id 
        WHERE s.approval_status = 'APPROVED'
    """
    params = []

    if q and q.strip():
        query += " AND (s.title LIKE ? OR s.description LIKE ?)"
        params.extend([f"%{q}%", f"%{q}%"])
    
    if category and category not in ["All", "Semua Kategori"]:
        query += " AND s.category = ?"
        params.append(category)
        
    if min_price is not None:
        query += " AND s.price >= ?"
        params.append(min_price)
        
    if max_price is not None:
        query += " AND s.price <= ?"
        params.append(max_price)
        
    if campus:
        query += " AND u.campus = ?"
        params.append(campus)

    query += " ORDER BY s.id DESC"

    cursor.execute(query, params)
    services = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return services

@app.post("/services")
async def create_service(
    request: Request,
    title: str = Form(...),
    description: str = Form(...),
    category: str = Form(...),
    price: int = Form(...),
    max_price: Optional[int] = Form(None),
    campus: str = Form(...),
    meetup_location: str = Form(...),
    file: Optional[UploadFile] = File(None)
):
    current_user = get_current_user(request)
    
    image_url = ""
    if file and file.filename:
        file_path = f"uploads/{file.filename}"
        with open(file_path, "wb") as f:
            f.write(await file.read())
        image_url = f"/uploads/{file.filename}"
        
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("INSERT INTO services (seller_id, title, description, category, price, max_price, campus, meetup_location, image_url, approval_status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'PENDING')",
        (current_user["user_id"], title, description, category, price, max_price, campus, meetup_location, image_url))
    conn.commit()
    conn.close()
    return {"message": "Service created successfully"}

@app.put("/services/{service_id}")
async def update_service(
    service_id: int,
    request: Request,
    title: str = Form(...),
    description: str = Form(...),
    category: str = Form(...),
    price: int = Form(...),
    max_price: Optional[int] = Form(None),
    campus: str = Form(...),
    meetup_location: str = Form(...),
    file: Optional[UploadFile] = File(None)
):
    current_user = get_current_user(request)
    
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    cursor.execute("SELECT * FROM services WHERE id = ?", (service_id,))
    service = cursor.fetchone()
    
    if not service:
        conn.close()
        raise HTTPException(status_code=404, detail="Service tidak ditemukan")
        
    if service["seller_id"] != current_user["user_id"]:
        conn.close()
        raise HTTPException(status_code=403, detail="Anda tidak berhak mengedit layanan ini")
        
    image_url = service["image_url"]
    if file and file.filename:
        file_path = f"uploads/{file.filename}"
        with open(file_path, "wb") as f:
            f.write(await file.read())
        image_url = f"/uploads/{file.filename}"
        
    cursor.execute('''
        UPDATE services 
        SET title=?, description=?, price=?, category=?, max_price=?, campus=?, meetup_location=?, image_url=?
        WHERE id=?
    ''', (title, description, price, category, max_price, campus, meetup_location, image_url, service_id))
    
    conn.commit()
    conn.close()
    return {"message": "Service updated successfully"}

@app.get("/user/listings")
async def get_user_listings(request: Request):
    current_user = get_current_user(request)
    
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    cursor.execute('''
        SELECT p.*, u.name as seller_name, u.campus as seller_campus 
        FROM products p 
        JOIN users u ON p.seller_id = u.id 
        WHERE p.seller_id = ?
        ORDER BY p.id DESC
    ''', (current_user["user_id"],))
    products = [dict(row) for row in cursor.fetchall()]
    
    cursor.execute('''
        SELECT s.*, u.name as seller_name, u.campus as seller_campus 
        FROM services s 
        JOIN users u ON s.seller_id = u.id 
        WHERE s.seller_id = ?
        ORDER BY s.id DESC
    ''', (current_user["user_id"],))
    services = [dict(row) for row in cursor.fetchall()]
    
    conn.close()
    
    # Parse advanced details and tags for products
    for p in products:
        p["advanced_details"] = {}
        if "advanced_details" in p and p["advanced_details"]:
            try:
                p["advanced_details"] = json.loads(p["advanced_details"])
            except Exception:
                pass
                
        p["tags"] = []
        if "tags" in p and p["tags"]:
            try:
                p["tags"] = json.loads(p["tags"])
            except Exception:
                pass
                
    return {"products": products, "services": services}

@app.get("/user/profile")
async def user_profile(request: Request):
    current_user = get_current_user(request)
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute("SELECT id, name, email, campus, points, role, verification_status FROM users WHERE id = ?", (current_user["user_id"],))
    user = cursor.fetchone()
    conn.close()
    if user:
        return dict(user)
    raise HTTPException(status_code=404, detail="User not found")

# NOTIFICATION ENDPOINTS
@app.get("/notifications/unread_count")
async def get_unread_notifications_count(request: Request):
    current_user = get_current_user(request)
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute('''
        SELECT COUNT(*) FROM notifications 
        WHERE user_id = ? AND is_read = 0
    ''', (current_user["user_id"],))
    count = cursor.fetchone()[0]
    conn.close()
    return {"unread_count": count}
@app.get("/notifications")
async def get_notifications(request: Request):
    current_user = get_current_user(request)
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute('''
        SELECT * FROM notifications 
        WHERE user_id = ? 
        ORDER BY created_at DESC
    ''', (current_user["user_id"],))
    notifs = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return notifs

@app.post("/notifications/{notif_id}/read")
async def read_notification(request: Request, notif_id: int):
    current_user = get_current_user(request)
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute('''
        UPDATE notifications SET is_read = 1 
        WHERE id = ? AND user_id = ?
    ''', (notif_id, current_user["user_id"]))
    conn.commit()
    conn.close()
    return {"status": "success"}

# ADMIN ENDPOINTS

def verify_admin(request: Request):
    user = get_current_user(request)
    if user.get("role") != "ADMIN":
        raise HTTPException(status_code=403, detail="Admin access required")
    return user

@app.get("/admin/users")
async def admin_get_users(request: Request):
    verify_admin(request)
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute("SELECT id, name, email, campus, role, verification_status FROM users WHERE verification_status = 'PENDING'")
    users = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return users

@app.post("/admin/users/{user_id}/{action}")
async def admin_action_user(request: Request, user_id: int, action: str):
    verify_admin(request)
    if action not in ["approve", "reject"]:
        raise HTTPException(status_code=400, detail="Invalid action")
        
    status = "APPROVED" if action == "approve" else "REJECTED"
    
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("UPDATE users SET verification_status = ? WHERE id = ?", (status, user_id))
    conn.commit()
    conn.close()
    return {"message": f"User {action}d successfully"}

@app.get("/admin/products")
async def admin_get_products(request: Request):
    verify_admin(request)
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute('''
        SELECT p.*, u.name as seller_name 
        FROM products p
        JOIN users u ON p.seller_id = u.id
        WHERE p.approval_status = 'PENDING'
    ''')
    items = [dict(row) for row in cursor.fetchall()]
    # parse tags for json
    for item in items:
        if item.get("tags"):
            try:
                import json
                item["tags"] = json.loads(item["tags"])
            except:
                item["tags"] = []
    conn.close()
    return items

@app.post("/admin/products/{product_id}/{action}")
async def admin_action_product(request: Request, product_id: int, action: str):
    verify_admin(request)
    if action not in ["approve", "reject"]:
        raise HTTPException(status_code=400, detail="Invalid action")
        
    status = "APPROVED" if action == "approve" else "REJECTED"
    
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("UPDATE products SET approval_status = ? WHERE id = ?", (status, product_id))
    conn.commit()
    conn.close()
    return {"message": f"Product {action}d successfully"}

@app.get("/admin/services")
async def admin_get_services(request: Request):
    verify_admin(request)
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute('''
        SELECT s.*, u.name as seller_name 
        FROM services s
        JOIN users u ON s.seller_id = u.id
        WHERE s.approval_status = 'PENDING'
    ''')
    items = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return items

@app.post("/admin/services/{service_id}/{action}")
async def admin_action_service(request: Request, service_id: int, action: str):
    verify_admin(request)
    if action not in ["approve", "reject"]:
        raise HTTPException(status_code=400, detail="Invalid action")
        
    status = "APPROVED" if action == "approve" else "REJECTED"
    
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("UPDATE services SET approval_status = ? WHERE id = ?", (status, service_id))
    conn.commit()
    conn.close()
    return {"message": f"Service {action}d successfully"}

@app.put('/products/{product_id}')
async def update_product(product_id: int, request: Request):
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    
    form_data = await request.form()
    
    fields = []
    params = []
    
    for key in ['name', 'description', 'price', 'category', 'condition', 'campus', 'item_type']:
        if key in form_data:
            fields.append(f'{key} = ?')
            val = form_data[key]
            if key == 'price':
                try: val = int(val)
                except: val = 0
            params.append(val)
            
    if 'tags' in form_data:
        fields.append('tags = ?')
        params.append(form_data['tags'])
        
    if 'advanced_details' in form_data:
        fields.append('advanced_details = ?')
        params.append(form_data['advanced_details'])

    if 'image' in form_data and hasattr(form_data['image'], 'filename') and form_data['image'].filename:
        image_file = form_data['image']
        import uuid
        import shutil
        filename = f"{uuid.uuid4()}_{image_file.filename}"
        file_path = os.path.join(UPLOAD_DIR, filename)
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(image_file.file, buffer)
        image_url = f"/static/uploads/{filename}"
        fields.append('image_url = ?')
        params.append(image_url)

    if not fields:
        return {"status": "no_changes"}

    params.append(product_id)
    query = f"UPDATE products SET {', '.join(fields)} WHERE id = ?"
    cursor.execute(query, params)
    conn.commit()
    conn.close()
    return {"status": "success"}

@app.delete('/products/{product_id}')
async def delete_product(product_id: int):
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("DELETE FROM products WHERE id = ?", (product_id,))
    conn.commit()
    conn.close()
    return {"status": "success"}

@app.delete('/services/{service_id}')
async def delete_service(service_id: int):
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("DELETE FROM services WHERE id = ?", (service_id,))
    conn.commit()
    conn.close()
    return {"status": "success"}

@app.put('/services/{service_id}')
async def update_service(service_id: int, request: Request):
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    
    form_data = await request.form()
    
    fields = []
    params = []
    
    for key in ['title', 'description', 'price', 'category']:
        if key in form_data:
            fields.append(f'{key} = ?')
            val = form_data[key]
            if key == 'price':
                try: val = int(val)
                except: val = 0
            params.append(val)

    if 'image' in form_data and hasattr(form_data['image'], 'filename') and form_data['image'].filename:
        image_file = form_data['image']
        import uuid
        import shutil
        filename = f"{uuid.uuid4()}_{image_file.filename}"
        file_path = os.path.join(UPLOAD_DIR, filename)
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(image_file.file, buffer)
        image_url = f"/static/uploads/{filename}"
        fields.append('image_url = ?')
        params.append(image_url)

    if not fields:
        return {"status": "no_changes"}

    params.append(service_id)
    query = f"UPDATE services SET {', '.join(fields)} WHERE id = ?"
    cursor.execute(query, params)
    conn.commit()
    conn.close()
    return {"status": "success"}

@app.post("/cart")
async def add_to_cart(request: Request, cart_item: CartItemCreate):
    current_user = get_current_user(request)
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    
    # Check if product exists
    cursor.execute("SELECT id FROM products WHERE id = ?", (cart_item.product_id,))
    if not cursor.fetchone():
        conn.close()
        raise HTTPException(status_code=404, detail="Product not found")
        
    # Check if already in cart
    cursor.execute("SELECT id, quantity FROM carts WHERE user_id = ? AND product_id = ?", (current_user["user_id"], cart_item.product_id))
    existing = cursor.fetchone()
    
    if existing:
        new_quantity = existing[1] + cart_item.quantity
        cursor.execute("UPDATE carts SET quantity = ? WHERE id = ?", (new_quantity, existing[0]))
    else:
        cursor.execute("INSERT INTO carts (user_id, product_id, quantity) VALUES (?, ?, ?)", 
                       (current_user["user_id"], cart_item.product_id, cart_item.quantity))
                       
    conn.commit()
    conn.close()
    return {"message": "Item added to cart"}

@app.get("/cart")
async def get_cart(request: Request):
    current_user = get_current_user(request)
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    cursor.execute('''
        SELECT c.id as cart_id, c.quantity, p.* 
        FROM carts c
        JOIN products p ON c.product_id = p.id
        WHERE c.user_id = ?
    ''', (current_user["user_id"],))
    
    cart_items = [dict(row) for row in cursor.fetchall()]
    conn.close()
    
    # Parse tags back to list for frontend
    for item in cart_items:
        try:
            item["tags"] = json.loads(item["tags"])
        except:
            item["tags"] = []
            
    return {"cart_items": cart_items}

@app.delete("/cart/{cart_id}")
async def remove_from_cart(cart_id: int, request: Request):
    current_user = get_current_user(request)
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    
    cursor.execute("DELETE FROM carts WHERE id = ? AND user_id = ?", (cart_id, current_user["user_id"]))
    changes = cursor.rowcount
    conn.commit()
    conn.close()
    
    if changes == 0:
        raise HTTPException(status_code=404, detail="Cart item not found or unauthorized")
        
    return {"message": "Item removed from cart"}

@app.put("/cart/{cart_id}")
async def update_cart_quantity(cart_id: int, cart_item: CartItemUpdate, request: Request):
    current_user = get_current_user(request)
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    
    if cart_item.quantity < 1:
        conn.close()
        raise HTTPException(status_code=400, detail="Quantity must be at least 1")
        
    cursor.execute("UPDATE carts SET quantity = ? WHERE id = ? AND user_id = ?", 
                   (cart_item.quantity, cart_id, current_user["user_id"]))
    changes = cursor.rowcount
    conn.commit()
    conn.close()
    
    if changes == 0:
        raise HTTPException(status_code=404, detail="Cart item not found or unauthorized")
        
    return {"message": "Cart quantity updated successfully"}

@app.post("/checkout")
async def checkout(request: Request, checkout_data: CheckoutRequest):
    current_user = get_current_user(request)
    user_id = current_user["user_id"]
    
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    # Ambil semua barang dari keranjang
    cursor.execute('''
        SELECT c.product_id, c.quantity, p.price, p.seller_id, p.name 
        FROM carts c
        JOIN products p ON c.product_id = p.id
        WHERE c.user_id = ?
    ''', (user_id,))
    
    cart_items = cursor.fetchall()
    
    if not cart_items:
        conn.close()
        raise HTTPException(status_code=400, detail="Cart is empty")
        
    total_amount = sum(int(item["price"]) * int(item["quantity"]) for item in cart_items)
    
    # Buat pesanan baru
    cursor.execute(
        "INSERT INTO orders (user_id, total_amount, payment_method, delivery_address) VALUES (?, ?, ?, ?)",
        (user_id, total_amount, checkout_data.payment_method, checkout_data.delivery_address)
    )
    order_id = cursor.lastrowid
    
    # Pindahkan dari keranjang ke order_items dan buat notifikasi
    for item in cart_items:
        cursor.execute(
            "INSERT INTO order_items (order_id, product_id, quantity, price_at_checkout) VALUES (?, ?, ?, ?)",
            (order_id, item["product_id"], item["quantity"], item["price"])
        )
        # Notifikasi untuk penjual
        cursor.execute(
            "INSERT INTO notifications (user_id, title, message) VALUES (?, ?, ?)",
            (item["seller_id"], "Pesanan Baru", f"Barang '{item['name']}' telah dipesan.")
        )
        
    # Kosongkan keranjang
    cursor.execute("DELETE FROM carts WHERE user_id = ?", (user_id,))
    
    conn.commit()
    conn.close()
    
    return {"message": "Checkout successful", "order_id": order_id, "total_amount": total_amount}

@app.put("/orders/{order_id}/complete")
async def complete_order(order_id: int, request: Request):
    current_user = get_current_user(request)
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    
    cursor.execute("UPDATE orders SET status = 'Selesai' WHERE id = ? AND user_id = ?", (order_id, current_user["user_id"]))
    changes = cursor.rowcount
    
    if changes > 0:
        cursor.execute(
            "INSERT INTO notifications (user_id, title, message) VALUES (?, ?, ?)",
            (current_user["user_id"], "Pembayaran Berhasil", f"Pesanan #{order_id} berhasil dibayar.")
        )
    
    conn.commit()
    conn.close()
    
    if changes == 0:
        raise HTTPException(status_code=404, detail="Order not found or unauthorized")
        
    return {"message": "Order marked as completed"}

@app.get("/orders/{order_id}")
async def get_order(order_id: int, request: Request):
    current_user = get_current_user(request)
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    # Ambil detail pesanan
    cursor.execute("SELECT * FROM orders WHERE id = ? AND user_id = ?", (order_id, current_user["user_id"]))
    order = cursor.fetchone()
    
    if not order:
        conn.close()
        raise HTTPException(status_code=404, detail="Order not found")
        
    # Ambil barang-barang di pesanan ini
    cursor.execute('''
        SELECT oi.quantity, oi.price_at_checkout as price, p.name, p.image_url 
        FROM order_items oi
        JOIN products p ON oi.product_id = p.id
        WHERE oi.order_id = ?
    ''', (order_id,))
    items = [dict(row) for row in cursor.fetchall()]
    
    conn.close()
    
    order_dict = dict(order)
    order_dict["items"] = items
    
    return order_dict

@app.get("/orders")
async def get_orders(request: Request):
    current_user = get_current_user(request)
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    # Ambil semua pesanan milik user, diurutkan dari yang terbaru
    cursor.execute("SELECT * FROM orders WHERE user_id = ? ORDER BY created_at DESC", (current_user["user_id"],))
    orders = cursor.fetchall()
    
    result = []
    for order in orders:
        order_dict = dict(order)
        # Ambil satu barang saja (barang pertama) untuk ditampilkan di riwayat
        cursor.execute('''
            SELECT oi.quantity, oi.price_at_checkout as price, p.name, p.image_url 
            FROM order_items oi
            JOIN products p ON oi.product_id = p.id
            WHERE oi.order_id = ?
            LIMIT 1
        ''', (order["id"],))
        first_item = cursor.fetchone()
        
        # Hitung total jenis barang
        cursor.execute("SELECT COUNT(*) FROM order_items WHERE order_id = ?", (order["id"],))
        total_items = cursor.fetchone()[0]
        
        if first_item:
            order_dict["first_item"] = dict(first_item)
            order_dict["total_item_types"] = total_items
            
        result.append(order_dict)
        
    conn.close()
    return result

@app.get("/wishlist")
async def get_wishlist(request: Request):
    current_user = get_current_user(request)
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute('''
        SELECT p.* 
        FROM wishlists w
        JOIN products p ON w.product_id = p.id
        WHERE w.user_id = ?
    ''', (current_user["user_id"],))
    items = [dict(row) for row in cursor.fetchall()]
    conn.close()
    
    for item in items:
        try:
            item["tags"] = json.loads(item["tags"])
        except:
            item["tags"] = []
            
    return {"items": items}

@app.post("/wishlist/{product_id}")
async def toggle_wishlist(request: Request, product_id: int):
    current_user = get_current_user(request)
    user_id = current_user["user_id"]
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    
    cursor.execute("SELECT id FROM wishlists WHERE user_id = ? AND product_id = ?", (user_id, product_id))
    existing = cursor.fetchone()
    
    if existing:
        cursor.execute("DELETE FROM wishlists WHERE id = ?", (existing[0],))
        message = "Removed from wishlist"
    else:
        cursor.execute("INSERT INTO wishlists (user_id, product_id) VALUES (?, ?)", (user_id, product_id))
        message = "Added to wishlist"
        
    conn.commit()
    conn.close()
    return {"message": message}

@app.get("/wishlist/{product_id}/check")
async def check_wishlist(request: Request, product_id: int):
    current_user = get_current_user(request)
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    
    cursor.execute("SELECT id FROM wishlists WHERE user_id = ? AND product_id = ?", (current_user["user_id"], product_id))
    existing = cursor.fetchone()
    conn.close()
    
    return {"is_wishlisted": bool(existing)}


if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app, host='0.0.0.0', port=8000)
