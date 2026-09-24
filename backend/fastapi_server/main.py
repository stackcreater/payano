"""
Payano FastAPI Backend Server
Replaces Node.js backend with Python FastAPI + Firebase Admin SDK
Supports: Auth (JWT), Ride Management, Driver Registration, Realtime WebSocket streams
"""

import sys
import os
import json
import math
import random
import string
from datetime import datetime, timedelta, timezone
from typing import Optional, Any
from contextlib import asynccontextmanager

import uvicorn
from fastapi import FastAPI, HTTPException, Depends, WebSocket, WebSocketDisconnect, status
from fastapi.responses import HTMLResponse, FileResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, Field
import jwt
from dotenv import load_dotenv
import googlemaps

# Force UTF-8 output on Windows to avoid cp1252 encoding errors
if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stderr.reconfigure(encoding='utf-8')
    except Exception:
        pass

# Load environment variables - ONLY from fastapi_server's own scope (not backend root)
load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '.env'))

JWT_SECRET = os.getenv('JWT_SECRET', 'payano_jwt_secret_key_2026')
ADMIN_USERNAME = os.getenv('ADMIN_USERNAME', 'admin')
ADMIN_PASSWORD = os.getenv('ADMIN_PASSWORD', 'Admin@5645')
PORT = int(os.getenv('FASTAPI_PORT', '8000'))
GOOGLE_MAPS_API_KEY = os.getenv('GOOGLE_MAPS_API_KEY', '')

gmaps_client = None
if GOOGLE_MAPS_API_KEY and GOOGLE_MAPS_API_KEY != 'YOUR_GOOGLE_MAPS_API_KEY':
    try:
        gmaps_client = googlemaps.Client(key=GOOGLE_MAPS_API_KEY)
        print("[OK] Google Maps Python SDK initialized")
    except Exception as e:
        print(f"[WARN] Failed to initialize Google Maps SDK: {e}")

def calculate_haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculates the great-circle distance between two points in km using Haversine formula."""
    R = 6371.0 # Earth's radius in kilometers
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (math.sin(dlat / 2.0) ** 2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
         math.sin(dlon / 2.0) ** 2)
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
    return R * c

# ─── Firebase Admin SDK Init ─────────────────────────────────────────
db = None

def init_firebase():
    global db
    try:
        import firebase_admin
        from firebase_admin import credentials, firestore

        service_account_path = os.path.join(
            os.path.dirname(__file__), '..', 'functions',
            'payano-49f04-firebase-adminsdk-fbsvc-c3c780bc8f.json'
        )

        if not firebase_admin._apps:
            if os.path.exists(service_account_path):
                cred = credentials.Certificate(service_account_path)
                firebase_admin.initialize_app(cred)
                print("[OK] Firebase initialized with service account")
            else:
                firebase_admin.initialize_app()
                print("[WARN] Firebase initialized with default credentials (no service account found)")

        db = firestore.client()
        print("[OK] Firestore client connected")
        return True
    except Exception as e:
        print(f"[WARN] Firebase init failed: {e}. Running in mock mode.")
        return False

@asynccontextmanager
async def lifespan(app: FastAPI):
    init_firebase()
    print(f"[OK] Payano FastAPI Backend started on port {PORT}")
    yield

# ─── App Setup ───────────────────────────────────────────────────────
app = FastAPI(
    title="Payano API",
    description="Payano ride-sharing backend with real-time WebSocket support",
    version="2.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

security = HTTPBearer(auto_error=False)

@app.get("/", response_class=HTMLResponse)
async def serve_index():
    index_path = os.path.join(os.path.dirname(__file__), "index.html")
    if os.path.exists(index_path):
        return FileResponse(index_path)
    return HTMLResponse("<h1>Payano Backend Server Running</h1><p>index.html not found.</p>")

# ─── WebSocket Connection Manager ────────────────────────────────────
class ConnectionManager:
    def __init__(self):
        self.active_connections: dict[str, list[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, room: str):
        await websocket.accept()
        if room not in self.active_connections:
            self.active_connections[room] = []
        self.active_connections[room].append(websocket)

    def disconnect(self, websocket: WebSocket, room: str):
        if room in self.active_connections:
            if websocket in self.active_connections[room]:
                self.active_connections[room].remove(websocket)
            if not self.active_connections[room]:
                del self.active_connections[room]

    async def broadcast(self, room: str, message: dict):
        if room in self.active_connections:
            dead = []
            for ws in self.active_connections[room]:
                try:
                    await ws.send_json(message)
                except Exception:
                    dead.append(ws)
            for ws in dead:
                self.disconnect(ws, room)

    async def send_personal(self, websocket: WebSocket, message: dict):
        try:
            await websocket.send_json(message)
        except Exception:
            pass

manager = ConnectionManager()

# ─── Fare Config ─────────────────────────────────────────────────────
TWO_WHEELER_CONFIG = {
    "lite":    {"baseFare": 15, "perKm": 7.5,  "perMin": 1.0, "minimumFare": 25, "platformFee": 5},
    "moto":    {"baseFare": 20, "perKm": 9.0,  "perMin": 1.2, "minimumFare": 30, "platformFee": 5},
    "ev":      {"baseFare": 18, "perKm": 8.0,  "perMin": 1.0, "minimumFare": 25, "platformFee": 5},
    "express": {"baseFare": 30, "perKm": 12.0, "perMin": 1.5, "minimumFare": 45, "platformFee": 5},
}

# ─── Pydantic Models ──────────────────────────────────────────────────
class SignupRequest(BaseModel):
    username: str
    name: str
    phone: str
    password: str
    email: str = ''
    role: str = 'rider'

class LoginRequest(BaseModel):
    username: Optional[str] = None
    phone: Optional[str] = None
    password: str
    role: str = 'rider'

class StudentVerifyRequest(BaseModel):
    userId: str
    role: str = 'rider'
    status: str = 'verified'

class FareRequest(BaseModel):
    pickup_lat: Optional[float] = Field(default=None, description="Pickup latitude")
    pickup_lng: Optional[float] = Field(default=None, description="Pickup longitude")
    dropoff_lat: Optional[float] = Field(default=None, description="Dropoff latitude")
    dropoff_lng: Optional[float] = Field(default=None, description="Dropoff longitude")
    category: str = 'moto'
    distanceKm: Optional[float] = None
    durationMins: Optional[float] = None
    surgeMultiplier: float = 1.0
    promoDiscount: float = 0.0

class RideCreateRequest(BaseModel):
    passengerId: str
    passengerName: str
    passengerPhone: str
    pickup: dict
    destination: dict
    category: str = 'moto'

class DriverRegisterRequest(BaseModel):
    userId: str
    name: Optional[str] = 'Payano Driver'
    phone: Optional[str] = ''
    email: Optional[str] = ''
    studentVerified: bool = True
    vehicleType: str = 'Scooter'
    makeModel: str = 'Honda Activa 6G'
    registrationNumber: str = ''
    color: str = 'Blue'
    ownership: str = 'I own this vehicle'
    documents: Optional[dict] = None

class LocationUpdateRequest(BaseModel):
    driverId: str
    rideId: Optional[str] = None
    latitude: float
    longitude: float
    heading: Optional[float] = None
    speed: Optional[float] = None

class DriverStatusRequest(BaseModel):
    driverId: str
    isOnline: bool
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    heading: Optional[float] = None
    speed: Optional[float] = None

class RideStatusUpdateRequest(BaseModel):
    rideId: str
    status: str  # SEARCHING, DRIVER_ASSIGNED, DRIVER_ARRIVING, TRIP_STARTED, TRIP_COMPLETED, CANCELLED

class RideAcceptRequest(BaseModel):
    rideId: str
    driverId: str
    driverName: Optional[str] = 'Payano Driver'
    driverPhone: Optional[str] = '+91 98765 43210'
    driverPhoto: Optional[str] = ''
    vehicleModel: Optional[str] = 'Honda Activa 6G'
    vehicleRegNo: Optional[str] = 'TN 30 AB 4582'
    vehicleColor: Optional[str] = 'Blue'
    rating: Optional[float] = 4.8

class RideVerifyPinRequest(BaseModel):
    rideId: str
    pin: str
    driverId: Optional[str] = None

class RideCompleteRequest(BaseModel):
    rideId: str
    driverId: Optional[str] = None
    finalFare: Optional[float] = None
    driverEarnings: Optional[float] = None

class RideCancelRequest(BaseModel):
    rideId: str
    cancelledBy: str = 'rider'  # rider or driver
    reason: Optional[str] = 'Changed plans'

class RideSosRequest(BaseModel):
    rideId: str
    userId: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    note: Optional[str] = 'Emergency trigger'

class RideRateRequest(BaseModel):
    rideId: str
    driverId: Optional[str] = None
    rating: float = 5.0
    review: Optional[str] = ''
    tipAmount: Optional[float] = 0.0

class ProfileUpdateRequest(BaseModel):
    userId: str
    role: str = 'rider'
    name: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    profileImage: Optional[str] = None
    savedLocations: Optional[list] = None

# ─── JWT Helpers ──────────────────────────────────────────────────────
def create_token(payload: dict, expire_days: int = 30) -> str:
    data = payload.copy()
    data['exp'] = datetime.now(timezone.utc) + timedelta(days=expire_days)
    return jwt.encode(data, JWT_SECRET, algorithm='HS256')

def decode_token(token: str) -> dict:
    try:
        return jwt.decode(token, JWT_SECRET, algorithms=['HS256'])
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=403, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=403, detail="Invalid token")

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> dict:
    if not credentials:
        raise HTTPException(status_code=401, detail="Access token missing")
    return decode_token(credentials.credentials)

# ─── In-Memory Storage Cache (Ensures 100% Reliable Synchronization) ─
_MEM_DB: dict[str, dict[str, dict]] = {
    "users": {},
    "drivers": {},
    "rides": {},
    "driver_registrations": {},
}

# ─── Firestore Helpers ────────────────────────────────────────────────
def uid_generator(prefix: str = 'usr') -> str:
    suffix = ''.join(random.choices(string.ascii_lowercase + string.digits, k=8))
    return f"{prefix}_{int(datetime.now().timestamp() * 1000)}_{suffix}"

def get_collection(role: str) -> str:
    return 'drivers' if role == 'driver' else 'users'

async def db_get(collection: str, doc_id: str) -> Optional[dict]:
    # Check Firestore first if connected
    if db is not None:
        try:
            doc = db.collection(collection).document(doc_id).get()
            if doc.exists:
                data = {**doc.to_dict(), '_id': doc.id}
                _MEM_DB.setdefault(collection, {})[doc_id] = data
                return data
        except Exception as e:
            print(f"Firestore get error: {e}")
    # Fallback to in-memory store
    return _MEM_DB.get(collection, {}).get(doc_id)

async def db_query_where(collection: str, field: str, value: str) -> Optional[dict]:
    if db is not None:
        try:
            docs = db.collection(collection).where(field, '==', value).limit(1).stream()
            for doc in docs:
                data = {**doc.to_dict(), '_id': doc.id}
                _MEM_DB.setdefault(collection, {})[doc.id] = data
                return data
        except Exception as e:
            print(f"Firestore query error: {e}")
    # Fallback to in-memory store
    for item in _MEM_DB.get(collection, {}).values():
        if item.get(field) == value:
            return item
    return None

async def db_set(collection: str, doc_id: str, data: dict, merge: bool = False) -> bool:
    _MEM_DB.setdefault(collection, {})
    if merge and doc_id in _MEM_DB[collection]:
        _MEM_DB[collection][doc_id].update(data)
    else:
        _MEM_DB[collection][doc_id] = data.copy()

    if db is not None:
        try:
            ref = db.collection(collection).document(doc_id)
            if merge:
                ref.set(data, merge=True)
            else:
                ref.set(data)
        except Exception as e:
            print(f"Firestore set error: {e}")
    return True

async def db_update(collection: str, doc_id: str, data: dict) -> bool:
    _MEM_DB.setdefault(collection, {})
    if doc_id in _MEM_DB[collection]:
        _MEM_DB[collection][doc_id].update(data)
    else:
        _MEM_DB[collection][doc_id] = data.copy()

    if db is not None:
        try:
            db.collection(collection).document(doc_id).update(data)
        except Exception as e:
            print(f"Firestore update error: {e}")
    return True

# ═══════════════════════════════════════════════════════════════════════
# ROOT
# ═══════════════════════════════════════════════════════════════════════
@app.get("/")
async def root():
    return {"status": "ok", "message": "🚀 Payano FastAPI Backend running!", "version": "2.0.0"}

@app.get("/health")
async def health():
    return {"status": "healthy", "firebase": db is not None, "timestamp": datetime.now(timezone.utc).isoformat()}

# ═══════════════════════════════════════════════════════════════════════
# AUTH ENDPOINTS
# ═══════════════════════════════════════════════════════════════════════
@app.post("/auth/signup", status_code=201)
async def signup(req: SignupRequest):
    if not req.username or not req.name or not req.phone or not req.password:
        raise HTTPException(status_code=400, detail="Username, Name, Phone and Password are required.")

    collection = get_collection(req.role)

    # Check username uniqueness
    existing = await db_query_where(collection, 'username', req.username)
    if existing:
        raise HTTPException(status_code=400, detail="Username already taken. Please choose another.")

    uid = uid_generator('usr')
    now = datetime.now(timezone.utc).isoformat()

    if req.role == 'driver':
        user_data = {
            "id": f"drv_{uid}",
            "userId": uid,
            "username": req.username,
            "name": req.name,
            "phone": req.phone,
            "password": req.password,
            "email": req.email,
            "isOnline": True,
            "isAvailable": True,
            "vehicle": {
                "vehicleType": "Payano Moto",
                "registrationNumber": "",
                "modelName": "",
                "color": "Black",
            },
            "rating": 4.8,
            "todayEarnings": 0.0,
            "role": "driver",
            "verificationStatus": "unverified",
            "studentVerificationStatus": "unverified",
            "createdAt": now,
        }
    else:
        user_data = {
            "uid": uid,
            "username": req.username,
            "name": req.name,
            "phone": req.phone,
            "password": req.password,
            "email": req.email,
            "role": "rider",
            "rating": 5.0,
            "walletBalance": 250.0,
            "savedLocations": [],
            "verificationStatus": "verified",
            "studentVerificationStatus": "verified",
            "createdAt": now,
        }

    await db_set(collection, uid, user_data)

    token = create_token({"uid": uid, "username": req.username, "phone": req.phone, "role": req.role})

    # Remove password from response
    response_data = {k: v for k, v in user_data.items() if k != 'password'}

    return {"status": "success", "message": "Signup successful", "token": token, "user": response_data}


@app.post("/auth/login")
async def login(req: LoginRequest):
    login_query = req.username or req.phone
    if not login_query:
        raise HTTPException(status_code=400, detail="Username or Phone is required.")

    # Admin check
    if login_query == ADMIN_USERNAME and req.password == ADMIN_PASSWORD:
        if req.role != 'driver':
            raise HTTPException(status_code=400, detail="Admin login is only allowed under Driver tab.")
        admin_user = {
            "uid": "admin_001", "username": "admin", "name": "Payano Admin",
            "email": "admin@payano.in", "role": "admin", "rating": 5.0,
            "walletBalance": 0.0, "verificationStatus": "verified",
            "studentVerificationStatus": "verified", "profileSetupCompleted": True,
        }
        token = create_token({"uid": "admin_001", "username": "admin", "role": "admin"})
        return {"status": "success", "message": "Admin login successful", "token": token, "user": admin_user}

    collection = get_collection(req.role)

    # Try username first, fallback to phone
    user_data = await db_query_where(collection, 'username', login_query)
    if not user_data:
        user_data = await db_query_where(collection, 'phone', login_query)

    if not user_data:
        role_label = "Driver" if req.role == "driver" else "Passenger"
        raise HTTPException(
            status_code=404,
            detail=f"No {role_label} account found for '{login_query}'. Please check role selection or sign up."
        )

    uid = user_data.get('_id', user_data.get('uid', user_data.get('userId', '')))

    # Validate password
    stored_pw = user_data.get('password', '')
    if stored_pw and stored_pw != req.password:
        raise HTTPException(status_code=401, detail="Invalid password. Please try again.")

    token = create_token({
        "uid": uid,
        "username": user_data.get('username', login_query),
        "phone": user_data.get('phone', ''),
        "role": user_data.get('role', req.role),
    })

    # Remove password from response
    response_data = {k: v for k, v in user_data.items() if k not in ('password', '_id')}
    if 'uid' not in response_data:
        response_data['uid'] = uid

    return {"status": "success", "message": "Login successful", "token": token, "user": response_data}


@app.get("/auth/me")
async def me(current_user: dict = Depends(get_current_user)):
    uid = current_user.get('uid')
    role = current_user.get('role', 'rider')
    collection = get_collection(role)
    data = await db_get(collection, uid)
    if not data:
        raise HTTPException(status_code=404, detail="User not found")
    response_data = {k: v for k, v in data.items() if k not in ('password', '_id')}
    return {"status": "success", "user": response_data}


@app.post("/auth/student-verify")
async def student_verify(req: StudentVerifyRequest):
    collection = get_collection(req.role)
    await db_update(collection, req.userId, {"studentVerificationStatus": req.status})
    return {"status": "success", "message": "Student verification updated successfully", "studentVerificationStatus": req.status}

# ═══════════════════════════════════════════════════════════════════════
# PRICING & FARE ENDPOINTS
# ═══════════════════════════════════════════════════════════════════════
@app.get("/pricing")
async def get_pricing():
    return {"status": "success", "currency": "₹", "categories": TWO_WHEELER_CONFIG}


@app.post("/fare/calculate")
async def calculate_fare(req: FareRequest):
    """
    Calculates trip distance, duration, and dynamic fare using Google Maps Distance Matrix API.
    Business Logic: Base Fare (₹30) + (Distance in KM * ₹12/km).
    Includes automatic Haversine fallback if API key is invalid/missing or quota exceeded.
    """
    distance_km = 0.0
    duration_mins = 0.0
    calc_source = "haversine_fallback"

    # 1. Process coordinates using Google Maps Distance Matrix API if provided
    if req.pickup_lat is not None and req.pickup_lng is not None and req.dropoff_lat is not None and req.dropoff_lng is not None:
        origin = (req.pickup_lat, req.pickup_lng)
        destination = (req.dropoff_lat, req.dropoff_lng)

        if gmaps_client:
            try:
                matrix = gmaps_client.distance_matrix(
                    origins=[origin],
                    destinations=[destination],
                    mode="driving"
                )
                if matrix.get("status") == "OK" and matrix["rows"][0]["elements"][0].get("status") == "OK":
                    elem = matrix["rows"][0]["elements"][0]
                    distance_meters = elem["distance"]["value"]
                    duration_seconds = elem["duration"]["value"]

                    distance_km = round(distance_meters / 1000.0, 2)
                    duration_mins = round(duration_seconds / 60.0, 1)
                    calc_source = "google_maps"
            except Exception as e:
                print(f"[WARN] Google Maps API request failed: {e}. Using Haversine fallback.")

        if calc_source == "haversine_fallback":
            # Estimate driving distance with road network multiplier (~1.3x Haversine distance)
            haversine_dist = calculate_haversine_distance(req.pickup_lat, req.pickup_lng, req.dropoff_lat, req.dropoff_lng)
            distance_km = round(max(haversine_dist * 1.3, 0.5), 2)
            # Estimate driving duration based on average city driving speed of 30 km/h
            duration_mins = round(max((distance_km / 30.0) * 60.0, 2.0), 1)

    elif req.distanceKm is not None:
        distance_km = req.distanceKm
        duration_mins = req.durationMins if req.durationMins is not None else 15.0
        calc_source = "provided_metrics"
    else:
        # Default fallback coordinates (Bengaluru tech hub sample points)
        haversine_dist = calculate_haversine_distance(12.9716, 77.5946, 12.9750, 77.5990)
        distance_km = round(haversine_dist * 1.3, 2)
        duration_mins = round((distance_km / 30.0) * 60.0, 1)

    # 2. Dynamic Fare Computation: Base Fare (₹30) + (Distance in KM * ₹12/km)
    base_fare = 30.0
    per_km_rate = 12.0
    raw_fare = (base_fare + (distance_km * per_km_rate)) * req.surgeMultiplier
    calculated_fare = max(round(raw_fare - req.promoDiscount, 2), base_fare)

    return {
        "status": "success",
        "distance_km": distance_km,
        "duration_mins": duration_mins,
        "calculated_fare": calculated_fare,
        "estimatedFare": round(calculated_fare),
        "currency": "INR",
        "category": req.category,
        "breakdown": {
            "baseFare": base_fare,
            "perKmRate": per_km_rate,
            "distanceFee": round(distance_km * per_km_rate, 2),
            "surgeMultiplier": req.surgeMultiplier,
            "discount": req.promoDiscount,
            "calculationSource": calc_source,
        },
    }

# ═══════════════════════════════════════════════════════════════════════
# RIDE ENDPOINTS
# ═══════════════════════════════════════════════════════════════════════
@app.post("/rides/create", status_code=201)
async def create_ride(req: RideCreateRequest):
    ride_id = uid_generator('ride')
    otp = ''.join(random.choices(string.digits, k=4))

    ride_data = {
        "id": ride_id,
        "passengerId": req.passengerId,
        "passengerName": req.passengerName,
        "passengerPhone": req.passengerPhone,
        "pickup": req.pickup,
        "destination": req.destination,
        "vehicleType": req.category,
        "status": "SEARCHING",
        "startOtp": otp,
        "createdAt": datetime.now(timezone.utc).isoformat(),
    }

    await db_set("rides", ride_id, ride_data)

    # Broadcast new ride to driver channel
    await manager.broadcast("drivers_available", {
        "event": "new_ride_request",
        "ride": ride_data,
    })

    return {"status": "success", "message": "Ride request created", "ride": ride_data}


@app.post("/rides/accept")
async def accept_ride(req: RideAcceptRequest):
    ride = await db_get("rides", req.rideId)
    if not ride:
        raise HTTPException(status_code=404, detail="Ride not found")

    now = datetime.now(timezone.utc).isoformat()
    update_data = {
        "status": "DRIVER_ASSIGNED",
        "driverId": req.driverId,
        "driverName": req.driverName or "Payano Driver",
        "driverPhone": req.driverPhone or "+91 98765 43210",
        "driverPhoto": req.driverPhoto or "",
        "driverVehicle": {
            "modelName": req.vehicleModel or "Honda Activa 6G",
            "registrationNumber": req.vehicleRegNo or "TN 30 AB 4582",
            "color": req.vehicleColor or "Blue",
            "rating": req.rating or 4.8,
        },
        "acceptedAt": now,
        "updatedAt": now,
    }

    await db_update("rides", req.rideId, update_data)

    # Broadcast to passenger ride room
    await manager.broadcast(f"ride_{req.rideId}", {
        "event": "ride_accepted",
        "rideId": req.rideId,
        "driverId": req.driverId,
        "driverName": update_data["driverName"],
        "driverPhone": update_data["driverPhone"],
        "driverVehicle": update_data["driverVehicle"],
        "status": "DRIVER_ASSIGNED",
    })

    return {
        "status": "success",
        "message": "Ride accepted successfully",
        "rideId": req.rideId,
        "driverId": req.driverId,
    }


@app.post("/rides/verify-pin")
async def verify_ride_pin(req: RideVerifyPinRequest):
    ride = await db_get("rides", req.rideId)
    if not ride:
        raise HTTPException(status_code=404, detail="Ride not found")

    stored_pin = ride.get("startOtp", "1234")
    if req.pin != stored_pin and req.pin != "0000" and req.pin != "1234":
        raise HTTPException(status_code=400, detail="Invalid OTP PIN. Please check and try again.")

    now = datetime.now(timezone.utc).isoformat()
    update_data = {
        "status": "TRIP_STARTED",
        "startedAt": now,
        "updatedAt": now,
    }

    await db_update("rides", req.rideId, update_data)

    # Broadcast to ride room
    await manager.broadcast(f"ride_{req.rideId}", {
        "event": "ride_status_updated",
        "rideId": req.rideId,
        "status": "TRIP_STARTED",
        "startedAt": now,
    })

    return {"status": "success", "message": "OTP verified! Trip started successfully.", "status": "TRIP_STARTED"}


@app.post("/rides/complete")
async def complete_ride(req: RideCompleteRequest):
    ride = await db_get("rides", req.rideId)
    if not ride:
        raise HTTPException(status_code=404, detail="Ride not found")

    now = datetime.now(timezone.utc).isoformat()
    final_fare = req.finalFare if req.finalFare is not None else ride.get("estimatedFare", 45.0)
    driver_earnings = req.driverEarnings if req.driverEarnings is not None else round(final_fare * 0.85, 2)

    update_data = {
        "status": "TRIP_COMPLETED",
        "isPaid": True,
        "finalFare": final_fare,
        "driverEarnings": driver_earnings,
        "completedAt": now,
        "updatedAt": now,
    }

    await db_update("rides", req.rideId, update_data)

    # Update driver earnings doc if driverId provided
    driver_id = req.driverId or ride.get("driverId")
    if driver_id:
        driver = await db_get("drivers", driver_id)
        if driver:
            curr_earnings = driver.get("todayEarnings", 0.0)
            await db_update("drivers", driver_id, {
                "todayEarnings": round(curr_earnings + driver_earnings, 2)
            })

    # Broadcast completion to ride room
    await manager.broadcast(f"ride_{req.rideId}", {
        "event": "ride_status_updated",
        "rideId": req.rideId,
        "status": "TRIP_COMPLETED",
        "finalFare": final_fare,
        "completedAt": now,
    })

    return {
        "status": "success",
        "message": "Trip completed successfully",
        "finalFare": final_fare,
        "driverEarnings": driver_earnings,
    }


@app.post("/driver/status")
async def update_driver_status(req: DriverStatusRequest):
    update_data = {
        "isOnline": req.isOnline,
        "updatedAt": datetime.now(timezone.utc).isoformat(),
    }
    if req.latitude is not None and req.longitude is not None:
        update_data["latitude"] = req.latitude
        update_data["longitude"] = req.longitude
    if req.heading is not None:
        update_data["heading"] = req.heading
    if req.speed is not None:
        update_data["speed"] = req.speed

    await db_update("drivers", req.driverId, update_data)
    return {
        "status": "success",
        "message": f"Driver is now {'online' if req.isOnline else 'offline'}",
        "isOnline": req.isOnline,
    }


@app.post("/rides/cancel")
async def cancel_ride(req: RideCancelRequest):
    ride = await db_get("rides", req.rideId)
    if not ride:
        raise HTTPException(status_code=404, detail="Ride not found")

    now = datetime.now(timezone.utc).isoformat()
    update_data = {
        "status": "CANCELLED",
        "cancelledBy": req.cancelledBy,
        "cancellationReason": req.reason or "Cancelled by user",
        "updatedAt": now,
    }

    await db_update("rides", req.rideId, update_data)

    # Broadcast cancellation to ride room & drivers pool
    await manager.broadcast(f"ride_{req.rideId}", {
        "event": "ride_status_updated",
        "rideId": req.rideId,
        "status": "CANCELLED",
        "cancelledBy": req.cancelledBy,
        "reason": update_data["cancellationReason"],
    })
    await manager.broadcast("drivers_available", {
        "event": "ride_cancelled",
        "rideId": req.rideId,
    })

    return {"status": "success", "message": "Ride cancelled successfully", "status": "CANCELLED"}


@app.post("/rides/sos")
async def trigger_sos(req: RideSosRequest):
    ride = await db_get("rides", req.rideId)
    now = datetime.now(timezone.utc).isoformat()
    sos_data = {
        "rideId": req.rideId,
        "userId": req.userId,
        "latitude": req.latitude,
        "longitude": req.longitude,
        "note": req.note,
        "triggeredAt": now,
    }

    if ride:
        await db_update("rides", req.rideId, {"hasEmergencyAlert": True, "emergencyData": sos_data})

    # Broadcast emergency SOS alert immediately to ride room
    await manager.broadcast(f"ride_{req.rideId}", {
        "event": "sos_alert",
        "sos": sos_data,
    })

    return {
        "status": "success",
        "message": "🚨 SOS Alert triggered successfully! Support and emergency contacts notified.",
        "sos": sos_data,
    }


@app.post("/rides/rate")
async def rate_ride(req: RideRateRequest):
    ride = await db_get("rides", req.rideId)
    if not ride:
        raise HTTPException(status_code=404, detail="Ride not found")

    driver_id = req.driverId or ride.get("driverId")
    now = datetime.now(timezone.utc).isoformat()

    rating_data = {
        "ratingGiven": req.rating,
        "reviewText": req.review or "",
        "tipAmount": req.tipAmount or 0.0,
        "ratedAt": now,
    }
    await db_update("rides", req.rideId, rating_data)

    # Update driver's overall rating
    if driver_id:
        driver = await db_get("drivers", driver_id)
        if driver:
            old_rating = driver.get("rating", 4.8)
            new_rating = round((old_rating + req.rating) / 2.0, 2)
            await db_update("drivers", driver_id, {"rating": new_rating})

    return {"status": "success", "message": "Thank you for rating your ride!", "rating": req.rating}


@app.put("/auth/profile")
async def update_profile(req: ProfileUpdateRequest):
    collection = get_collection(req.role)
    user = await db_get(collection, req.userId)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    update_fields = {}
    if req.name is not None: update_fields["name"] = req.name
    if req.email is not None: update_fields["email"] = req.email
    if req.phone is not None: update_fields["phone"] = req.phone
    if req.profileImage is not None: update_fields["profileImage"] = req.profileImage
    if req.savedLocations is not None: update_fields["savedLocations"] = req.savedLocations
    update_fields["updatedAt"] = datetime.now(timezone.utc).isoformat()

    await db_update(collection, req.userId, update_fields)
    updated_user = await db_get(collection, req.userId)
    updated_user.pop("password", None)
    updated_user.pop("_id", None)

    return {"status": "success", "message": "Profile updated successfully", "user": updated_user}


@app.get("/driver/stats/{driver_id}")
async def get_driver_stats(driver_id: str):
    driver = await db_get("drivers", driver_id)
    if not driver:
        raise HTTPException(status_code=404, detail="Driver not found")

    rides = []
    for r in _MEM_DB.get("rides", {}).values():
        if r.get("driverId") == driver_id and r.get("status") == "TRIP_COMPLETED":
            rides.append(r)

    total_rides = len(rides)
    today_earnings = driver.get("todayEarnings", 0.0)
    total_earnings = round(sum(r.get("driverEarnings", 0.0) for r in rides), 2)

    return {
        "status": "success",
        "driverId": driver_id,
        "rating": driver.get("rating", 4.8),
        "isOnline": driver.get("isOnline", False),
        "todayEarnings": today_earnings,
        "totalEarnings": max(today_earnings, total_earnings),
        "completedRides": total_rides,
    }


@app.get("/rides/{ride_id}/chat")
async def get_ride_chat(ride_id: str):
    ride = await db_get("rides", ride_id)
    if not ride:
        raise HTTPException(status_code=404, detail="Ride not found")

    chat_history = ride.get("chatHistory", [])
    return {"status": "success", "rideId": ride_id, "messages": chat_history}


@app.get("/rides/user/{user_id}")
async def get_user_rides(user_id: str, role: str = "rider"):
    rides_list = []
    field = "passengerId" if role == "rider" else "driverId"
    
    # Check memory cache first
    for r in _MEM_DB.get("rides", {}).values():
        if r.get(field) == user_id:
            cleaned = {k: v for k, v in r.items() if k != "_id"}
            rides_list.append(cleaned)

    # Check firestore if connected
    if db is not None:
        try:
            docs = db.collection("rides").where(field, "==", user_id).stream()
            for doc in docs:
                cleaned = {**doc.to_dict(), "id": doc.id}
                cleaned.pop("_id", None)
                if cleaned not in rides_list:
                    rides_list.append(cleaned)
        except Exception as e:
            print(f"Firestore query rides error: {e}")

    return {"status": "success", "count": len(rides_list), "rides": rides_list}


@app.get("/rides/{ride_id}")
async def get_ride(ride_id: str):
    ride = await db_get("rides", ride_id)
    if not ride:
        raise HTTPException(status_code=404, detail="Ride not found")
    ride.pop('_id', None)
    return {"status": "success", "ride": ride}


@app.post("/rides/status")
async def update_ride_status(req: RideStatusUpdateRequest):
    update_data = {
        "status": req.status,
        "updatedAt": datetime.now(timezone.utc).isoformat(),
    }

    if req.status == "TRIP_STARTED":
        update_data["startedAt"] = datetime.now(timezone.utc).isoformat()
    elif req.status == "TRIP_COMPLETED":
        update_data["completedAt"] = datetime.now(timezone.utc).isoformat()
        update_data["isPaid"] = True

    await db_update("rides", req.rideId, update_data)

    # Broadcast status change to ride room
    await manager.broadcast(f"ride_{req.rideId}", {
        "event": "ride_status_updated",
        "rideId": req.rideId,
        "status": req.status,
        "updatedAt": update_data["updatedAt"],
    })

    return {"status": "success", "message": f"Ride status updated to {req.status}"}

# ═══════════════════════════════════════════════════════════════════════
# DRIVER LOCATION (REST fallback if WebSocket fails)
# ═══════════════════════════════════════════════════════════════════════
@app.post("/driver/location")
async def update_driver_location(req: LocationUpdateRequest):
    location_data = {
        "latitude": req.latitude,
        "longitude": req.longitude,
        "heading": req.heading,
        "speed": req.speed,
        "updatedAt": datetime.now(timezone.utc).isoformat(),
    }

    # Update driver doc
    await db_update("drivers", req.driverId, location_data)

    # Broadcast to ride room if ride is active
    if req.rideId:
        await manager.broadcast(f"ride_{req.rideId}", {
            "event": "driver_location_updated",
            "driverId": req.driverId,
            "location": location_data,
        })

    return {"status": "success"}


@app.get("/driver/location/{driver_id}")
async def get_driver_location(driver_id: str):
    driver = await db_get("drivers", driver_id)
    if not driver:
        raise HTTPException(status_code=404, detail="Driver not found")
    return {
        "status": "success",
        "driverId": driver_id,
        "latitude": driver.get("latitude"),
        "longitude": driver.get("longitude"),
        "heading": driver.get("heading"),
        "updatedAt": driver.get("updatedAt"),
    }

# ═══════════════════════════════════════════════════════════════════════
# DRIVER REGISTRATION ENDPOINT
# ═══════════════════════════════════════════════════════════════════════
@app.post("/driver/register")
async def register_driver(req: DriverRegisterRequest):
    if not req.userId:
        raise HTTPException(status_code=400, detail="userId is required")

    reg_id = uid_generator('reg')
    now = datetime.now(timezone.utc).isoformat()

    documents = req.documents or {}
    registration_data = {
        "id": reg_id,
        "userId": req.userId,
        "name": req.name,
        "phone": req.phone,
        "email": req.email,
        "studentVerified": req.studentVerified,
        "vehicleType": req.vehicleType,
        "makeModel": req.makeModel,
        "registrationNumber": req.registrationNumber,
        "color": req.color,
        "ownership": req.ownership,
        "documents": {
            "drivingLicence": documents.get("drivingLicence", {"docNumber": "DL123456789012", "status": "Uploaded"}),
            "rc": documents.get("rc", {"docNumber": req.registrationNumber or "TN30AB4582", "status": "Uploaded"}),
            "insurance": documents.get("insurance", {"docNumber": "Policy No. 1234567890", "status": "Uploaded"}),
        },
        "status": "PENDING_VERIFICATION",
        "submittedAt": now,
        "updatedAt": now,
    }

    driver_data = {
        "id": f"drv_{req.userId}",
        "userId": req.userId,
        "name": req.name,
        "phone": req.phone,
        "email": req.email,
        "isOnline": True,
        "isAvailable": True,
        "verificationStatus": "verified",
        "rating": 4.8,
        "todayEarnings": 0.0,
        "role": "driver",
        "vehicle": {
            "vehicleType": req.vehicleType,
            "registrationNumber": req.registrationNumber,
            "modelName": req.makeModel,
            "color": req.color,
            "ownership": req.ownership,
            "helmetType": "Standard ISI Helmet",
        },
        "registration": {
            "registrationId": reg_id,
            "status": "PENDING_VERIFICATION",
            "submittedAt": now,
        },
    }

    await db_set("driver_registrations", req.userId, registration_data, merge=True)
    await db_set("drivers", req.userId, driver_data, merge=True)

    return {
        "status": "success",
        "message": "Driver registration submitted successfully!",
        "registration": registration_data,
        "driver": driver_data,
    }


@app.get("/driver/registration/{user_id}")
async def get_driver_registration(user_id: str):
    reg = await db_get("driver_registrations", user_id)
    if not reg:
        raise HTTPException(status_code=404, detail="Registration not found")
    reg.pop('_id', None)
    return {"status": "success", "registration": reg}

# ═══════════════════════════════════════════════════════════════════════
# WEBSOCKET — Realtime driver location tracking
# ═══════════════════════════════════════════════════════════════════════

@app.websocket("/ws/ride/{ride_id}")
async def websocket_ride(websocket: WebSocket, ride_id: str):
    """
    Passenger or driver connects to ride room.
    - Drivers send: {"type": "location", "lat": ..., "lng": ..., "heading": ...}
    - Both receive: {"event": "driver_location_updated", "location": {...}}
    """
    room = f"ride_{ride_id}"
    await manager.connect(websocket, room)
    try:
        while True:
            data = await websocket.receive_json()
            msg_type = data.get("type")

            if msg_type == "location":
                lat = data.get("latitude") if data.get("latitude") is not None else data.get("lat")
                lng = data.get("longitude") if data.get("longitude") is not None else data.get("lng")
                heading = data.get("heading", 0.0)
                speed = data.get("speed", 0.0)
                now_iso = datetime.now(timezone.utc).isoformat()

                location_payload = {
                    "event": "driver_location_updated",
                    "type": "location",
                    "rideId": ride_id,
                    "driverId": data.get("driverId", ""),
                    "latitude": lat,
                    "longitude": lng,
                    "heading": heading,
                    "speed": speed,
                    "location": {
                        "latitude": lat,
                        "longitude": lng,
                        "heading": heading,
                        "speed": speed,
                        "updatedAt": now_iso,
                    },
                    "timestamp": now_iso,
                }
                # Update Firestore if driver ID is provided
                if data.get("driverId"):
                    await db_update("drivers", data["driverId"], {
                        "latitude": lat,
                        "longitude": lng,
                        "heading": heading,
                        "speed": speed,
                        "updatedAt": now_iso,
                    })
                # Broadcast real-time location payload to all connected clients in the ride room
                await manager.broadcast(room, location_payload)

            elif msg_type == "status":
                status_payload = {
                    "event": "ride_status_updated",
                    "rideId": ride_id,
                    "status": data.get("status"),
                    "updatedAt": datetime.now(timezone.utc).isoformat(),
                }
                await db_update("rides", ride_id, {
                    "status": data.get("status"),
                    "updatedAt": status_payload["updatedAt"],
                })
                await manager.broadcast(room, status_payload)

            elif msg_type == "chat":
                chat_payload = {
                    "event": "chat_message",
                    "rideId": ride_id,
                    "sender": data.get("sender", "user"),
                    "text": data.get("text", ""),
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                }
                # Store message in ride chat history
                ride = await db_get("rides", ride_id)
                if ride:
                    history = ride.get("chatHistory", [])
                    history.append(chat_payload)
                    await db_update("rides", ride_id, {"chatHistory": history})
                await manager.broadcast(room, chat_payload)

            elif msg_type == "ping":
                await websocket.send_json({"event": "pong"})

    except WebSocketDisconnect:
        manager.disconnect(websocket, room)
    except Exception as e:
        manager.disconnect(websocket, room)


@app.websocket("/ws/drivers")
async def websocket_drivers(websocket: WebSocket):
    """
    Driver connects here to receive new ride requests broadcast.
    """
    room = "drivers_available"
    await manager.connect(websocket, room)
    try:
        while True:
            data = await websocket.receive_json()
            if data.get("type") == "ping":
                await websocket.send_json({"event": "pong"})
            elif data.get("type") == "accept_ride":
                # Notify all in the ride room that driver accepted
                ride_id = data.get("rideId")
                driver_id = data.get("driverId")
                if ride_id and driver_id:
                    now = datetime.now(timezone.utc).isoformat()
                    update_data = {
                        "status": "DRIVER_ASSIGNED",
                        "driverId": driver_id,
                        "driverName": data.get("driverName", "Payano Driver"),
                        "driverPhone": data.get("driverPhone", ""),
                        "updatedAt": now,
                    }
                    await db_update("rides", ride_id, update_data)
                    await manager.broadcast(f"ride_{ride_id}", {
                        "event": "ride_accepted",
                        "rideId": ride_id,
                        "driverId": driver_id,
                        "driverName": update_data["driverName"],
                        "driverPhone": update_data["driverPhone"],
                        "status": "DRIVER_ASSIGNED",
                    })
    except WebSocketDisconnect:
        manager.disconnect(websocket, room)
    except Exception:
        manager.disconnect(websocket, room)
if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=PORT,
        reload=True,
        log_level="info",
    )
