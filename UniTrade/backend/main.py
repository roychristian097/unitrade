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
            approval_status TEXT DEFAULT 'PENDING',
            FOREIGN KEY(seller_id) REFERENCES users(id)
        )
    ''')
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS services (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            seller_id INTEGER,
            title TEXT,
            description TEXT,
            category TEXT,
            price INTEGER,
            image_url TEXT,
            approval_status TEXT DEFAULT 'PENDING',
            FOREIGN KEY(seller_id) REFERENCES users(id)
        )
    ''')
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            buyer_id INTEGER,
            total_amount INTEGER,
            status TEXT DEFAULT 'PENDING',
            payment_method TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(buyer_id) REFERENCES users(id)
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
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(sender_id) REFERENCES users(id),
            FOREIGN KEY(receiver_id) REFERENCES users(id),
            FOREIGN KEY(product_id) REFERENCES products(id)
        )
    ''')
    
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
        cursor.executemany("INSERT INTO products (seller_id, name, description, price, category, condition, campus, tags, image_url, approval_status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", dummy_products)
        
        dummy_services = [
            (user_id, "Jasa Rakit PC / Install Ulang Laptop", "Menerima jasa rakit PC rapi, install Windows, Linux.", "IT Support", 100000, "", "APPROVED"),
            (user_id, "Jasa Desain Poster / UI UX", "Bisa desain pakai Figma atau Canva.", "Desain", 50000, "", "APPROVED")
        ]
        cursor.executemany("INSERT INTO services (seller_id, title, description, category, price, image_url, approval_status) VALUES (?, ?, ?, ?, ?, ?, ?)", dummy_services)
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

@app.post("/register")
async def register(request: RegisterRequest):
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    try:
        cursor.execute("INSERT INTO users (name, email, password_hash, campus) VALUES (?, ?, ?, ?)", 
            (request.name, request.email, hash_password(request.password), request.campus))
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

@app.get("/campuses")
async def get_campuses():
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute('''
        SELECT campus FROM users WHERE campus IS NOT NULL AND campus != ''
        UNION
        SELECT campus FROM products WHERE campus IS NOT NULL AND campus != ''
    ''')
    campuses = [row[0] for row in cursor.fetchall()]
    conn.close()
    return campuses

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
        SELECT p.*, u.name as seller_name, u.campus as seller_campus 
        FROM products p
        JOIN users u ON p.seller_id = u.id
        WHERE p.approval_status = 'APPROVED'
    """
    params = []

    if q and q.strip():
        query += " AND (p.name LIKE ? OR p.description LIKE ?)"
        params.extend([f"%{q}%", f"%{q}%"])
    
    if category and category not in ["All", "Semua Kategori"]:
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

    query += " ORDER BY p.id DESC"

    cursor.execute(query, params)
    rows = cursor.fetchall()
    conn.close()

    results = []
    for row in rows:
        results.append({
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
            "image_url": row["image_url"]
        })

    return results

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
        INSERT INTO products (seller_id, name, description, price, category, condition, campus, tags, image_url) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', (current_user["user_id"], name, description, price, category, condition, campus, tags, image_url))
    conn.commit()
    new_id = cursor.lastrowid
    conn.close()
    return {"message": "Product created successfully", "id": new_id, "image_url": image_url}

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
    file: Optional[UploadFile] = File(None)
):
    current_user = get_current_user(request)
    
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    # Check if product exists and user is owner
    cursor.execute("SELECT * FROM products WHERE id = ?", (product_id,))
    product = cursor.fetchone()
    
    if not product:
        conn.close()
        raise HTTPException(status_code=404, detail="Product not found")
        
    if product["seller_id"] != current_user["user_id"]:
        conn.close()
        raise HTTPException(status_code=403, detail="Not authorized to edit this product")

    image_url = product["image_url"]
    if file and file.filename:
        file_path = f"uploads/{file.filename}"
        with open(file_path, "wb") as f:
            f.write(await file.read())
        image_url = f"/uploads/{file.filename}"
        
    cursor.execute('''
        UPDATE products 
        SET name = ?, description = ?, price = ?, category = ?, condition = ?, campus = ?, tags = ?, image_url = ?
        WHERE id = ?
    ''', (name, description, price, category, condition, campus, tags, image_url, product_id))
    
    conn.commit()
    conn.close()
    return {"message": "Product updated successfully", "id": product_id, "image_url": image_url}

@app.post("/messages")
async def send_message(request: Request, msg: MessageCreate):
    current_user = get_current_user(request)
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("INSERT INTO messages (sender_id, receiver_id, product_id, message) VALUES (?, ?, ?, ?)",
        (current_user["user_id"], msg.receiver_id, msg.product_id, msg.message))
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
async def create_service(request: Request, svc: ServiceCreate):
    current_user = get_current_user(request)
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("INSERT INTO services (seller_id, title, description, category, price, image_url) VALUES (?, ?, ?, ?, ?, ?)",
        (current_user["user_id"], svc.title, svc.description, svc.category, svc.price, ""))
    conn.commit()
    conn.close()
    return {"message": "Service created successfully"}

class OrderCreate(BaseModel):
    total_amount: int
    payment_method: str

@app.post("/checkout")
async def checkout(request: Request, order: OrderCreate):
    current_user = get_current_user(request)
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("INSERT INTO orders (buyer_id, total_amount, payment_method) VALUES (?, ?, ?)",
        (current_user["user_id"], order.total_amount, order.payment_method))
    conn.commit()
    conn.close()
    return {"message": "Order created successfully"}

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
