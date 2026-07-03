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
            campus TEXT
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
            FOREIGN KEY(seller_id) REFERENCES users(id)
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
    
    # Check if empty to seed data
    cursor.execute("SELECT COUNT(*) FROM users")
    if cursor.fetchone()[0] == 0:
        # Seed a dummy user
        cursor.execute("INSERT INTO users (name, email, password_hash, campus) VALUES (?, ?, ?, ?)", 
            ("Tester Student", "tester@student.ac.id", hash_password("123456"), "Universitas Nasional - Jakarta Selatan, Pasar Minggu"))
        user_id = cursor.lastrowid
        
        dummy_products = [
            (user_id, "MacBook Pro M1 2020 8/256GB", "Lancar jaya untuk ngoding, lecet pemakaian sedikit.", 12000000, "Elektronik", "Pemakaian Wajar (Fair/Used)", "Universitas Nasional - Jakarta Selatan, Pasar Minggu", json.dumps(["DORM ESSENTIALS", "GOOD"]), ""),
            (user_id, "Sony WH-1000XM4 Headphones", "Headphones over-ear Active Noise Cancelling terbaik. Kondisi istimewa, lengkap dengan kotak.", 2700000, "Elektronik", "Mulus (Like New)", "Universitas Nasional - Jakarta Selatan, Pasar Minggu", json.dumps(["PHONES", "LIKE NEW"]), ""),
            (user_id, "Jaket Hoodie Teknik Sipil 2023", "Hoodie tebal warna biru dongker. Belum pernah dipakai.", 150000, "Pakaian", "Baru (Brand New)", "Universitas Indonesia - Depok, Beji", json.dumps(["CLOTHING", "NEW"]), ""),
            (user_id, "Jasa Rakit PC / Install Ulang Laptop", "Menerima jasa rakit PC rapi, install Windows, Linux, dan aplikasi desain/arsitektur. Pengerjaan 1 hari.", 100000, "Jasa", "Semua Kondisi", "Universitas Nasional - Jakarta Selatan, Pasar Minggu", json.dumps(["SERVICES", "FAST"]), ""),
            (user_id, "Kalkulator Scientific Casio fx-991EX", "Cocok untuk mahasiswa teknik. Tombol masih empuk semua, fungsi normal.", 250000, "Elektronik", "Mulus (Like New)", "Universitas Gunadarma - Depok, Margonda", json.dumps(["STUDY", "LIKE NEW"]), "")
        ]
        cursor.executemany("INSERT INTO products (seller_id, name, description, price, category, condition, campus, tags, image_url) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", dummy_products)
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
        token = create_jwt({"user_id": user["id"], "name": user["name"], "campus": user["campus"]})
        return {
            "message": "Login berhasil!", 
            "token": token,
            "user": {"id": user["id"], "name": user["name"], "email": user["email"], "campus": user["campus"]}
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
        WHERE 1=1
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
    changes = conn.total_changes
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
    changes = conn.total_changes
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
        SELECT c.product_id, c.quantity, p.price 
        FROM carts c
        JOIN products p ON c.product_id = p.id
        WHERE c.user_id = ?
    ''', (user_id,))
    
    cart_items = cursor.fetchall()
    
    if not cart_items:
        conn.close()
        raise HTTPException(status_code=400, detail="Cart is empty")
        
    total_amount = sum(item["price"] * item["quantity"] for item in cart_items)
    
    # Buat pesanan baru
    cursor.execute(
        "INSERT INTO orders (user_id, total_amount, payment_method, delivery_address) VALUES (?, ?, ?, ?)",
        (user_id, total_amount, checkout_data.payment_method, checkout_data.delivery_address)
    )
    order_id = cursor.lastrowid
    
    # Pindahkan dari keranjang ke order_items
    for item in cart_items:
        cursor.execute(
            "INSERT INTO order_items (order_id, product_id, quantity, price_at_checkout) VALUES (?, ?, ?, ?)",
            (order_id, item["product_id"], item["quantity"], item["price"])
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
    changes = conn.total_changes
    
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
