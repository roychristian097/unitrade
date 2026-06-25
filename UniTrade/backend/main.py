from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI()

# Middleware CORS agar Flutter Web bisa mengakses API lokal tanpa diblokir
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Model Data untuk menerima input email & password dari Flutter
class LoginRequest(BaseModel):
    email: str
    password: str

# Database dummy produk dari sesi sebelumnya
products_db = [
    {"name": "laptop gaymink", "price": 12000000},
    {"name": "laptop gaymink", "price": 12000000}
]

@app.get("/products")
async def get_products():
    return products_db

# Endpoint API Login baru
@app.post("/login")
async def login(request: LoginRequest):
    # Akun percobaan sementara untuk malam ini
    if request.email == "test@unitrade.com" and request.password == "123456":
        return {"message": "Login berhasil!", "token": "rahasia_unitrade_123"}
    else:
        raise HTTPException(status_code=401, detail="Email atau password salah")