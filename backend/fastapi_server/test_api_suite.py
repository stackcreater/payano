"""
Comprehensive Test Suite for Payano FastAPI Backend Server
"""

import sys
import os
import json
import asyncio
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def run_tests():
    print("=" * 60)
    print("RUNNING PAYANO FASTAPI BACKEND TEST SUITE")
    print("=" * 60)

    results = {"passed": 0, "failed": 0, "issues": []}

    def test(name, test_func):
        try:
            test_func()
            print(f"  ✅ [PASS] {name}")
            results["passed"] += 1
        except AssertionError as e:
            print(f"  ❌ [FAIL] {name}: {e}")
            results["failed"] += 1
            results["issues"].append(f"{name}: {e}")
        except Exception as e:
            print(f"  💥 [ERROR] {name}: {e}")
            results["failed"] += 1
            results["issues"].append(f"{name} Error: {e}")

    # 1. Root & Health
    def test_root():
        res = client.get("/")
        assert res.status_code == 200
        assert "Payano" in res.text or "<!DOCTYPE html>" in res.text
    test("Root Endpoint GET /", test_root)

    def test_health():
        res = client.get("/health")
        assert res.status_code == 200
        assert res.json().get("status") == "healthy"
    test("Health Endpoint GET /health", test_health)

    # 2. Auth - Rider Signup & Login
    def test_rider_signup():
        payload = {
            "username": "testrider1",
            "name": "Test Rider",
            "phone": "+919999988888",
            "password": "Password123",
            "email": "rider@test.com",
            "role": "rider"
        }
        res = client.post("/auth/signup", json=payload)
        assert res.status_code == 201
        data = res.json()
        assert data.get("status") == "success"
        global RIDER_TOKEN, RIDER_UID
        RIDER_TOKEN = data["token"]
        RIDER_UID = data["user"].get("uid") or data["user"].get("id")
    test("Auth POST /auth/signup (Rider)", test_rider_signup)

    def test_rider_login():
        payload = {"username": "testrider1", "password": "Password123", "role": "rider"}
        res = client.post("/auth/login", json=payload)
        assert res.status_code == 200
    test("Auth POST /auth/login (Rider)", test_rider_login)

    # 3. Auth - Driver Signup & Login
    def test_driver_signup():
        payload = {
            "username": "testdriver1",
            "name": "Test Driver",
            "phone": "+918888877777",
            "password": "Password123",
            "email": "driver@test.com",
            "role": "driver"
        }
        res = client.post("/auth/signup", json=payload)
        assert res.status_code == 201
        data = res.json()
        global DRIVER_UID
        DRIVER_UID = data["user"].get("userId") or data["user"].get("uid") or data["user"].get("id")
    test("Auth POST /auth/signup (Driver)", test_driver_signup)

    def test_driver_login():
        payload = {"username": "testdriver1", "password": "Password123", "role": "driver"}
        res = client.post("/auth/login", json=payload)
        assert res.status_code == 200
    test("Auth POST /auth/login (Driver)", test_driver_login)

    # 4. Auth - Admin Login
    def test_admin_login():
        payload = {"username": "admin", "password": "Admin@5645", "role": "driver"}
        res = client.post("/auth/login", json=payload)
        assert res.status_code == 200
    test("Auth POST /auth/login (Admin)", test_admin_login)

    # 5. Auth GET /auth/me & PUT /auth/profile
    def test_auth_me():
        headers = {"Authorization": f"Bearer {RIDER_TOKEN}"}
        res = client.get("/auth/me", headers=headers)
        assert res.status_code == 200
    test("Auth GET /auth/me", test_auth_me)

    def test_profile_update():
        payload = {
            "userId": RIDER_UID,
            "name": "Updated Test Rider",
            "email": "updated_rider@test.com"
        }
        res = client.put("/auth/profile", json=payload)
        assert res.status_code == 200, f"Expected 200, got {res.status_code}: {res.text}"
        assert res.json()["user"]["name"] == "Updated Test Rider"
    test("PUT /auth/profile (Update Profile)", test_profile_update)

    # 6. Pricing & Fare
    def test_pricing():
        res = client.get("/pricing")
        assert res.status_code == 200
    test("GET /pricing", test_pricing)

    def test_fare_calculate():
        payload = {"category": "moto", "distanceKm": 5.0, "durationMins": 15.0}
        res = client.post("/fare/calculate", json=payload)
        assert res.status_code == 200
    test("POST /fare/calculate", test_fare_calculate)

    # 7. Ride Creation & Details
    def test_ride_create():
        payload = {
            "passengerId": RIDER_UID,
            "passengerName": "Test Rider",
            "passengerPhone": "+919999988888",
            "pickup": {"address": "Hostel 4", "latitude": 12.9716, "longitude": 77.5946},
            "destination": {"address": "Library", "latitude": 12.9750, "longitude": 77.5990},
            "category": "moto"
        }
        res = client.post("/rides/create", json=payload)
        assert res.status_code == 201
        data = res.json()
        global CREATED_RIDE_ID, CREATED_RIDE_OTP
        CREATED_RIDE_ID = data["ride"]["id"]
        CREATED_RIDE_OTP = data["ride"]["startOtp"]
    test("POST /rides/create", test_ride_create)

    def test_get_ride():
        res = client.get(f"/rides/{CREATED_RIDE_ID}")
        assert res.status_code == 200
    test("GET /rides/{ride_id}", test_get_ride)

    # 8. Accept, Verify OTP, Complete
    def test_accept_ride():
        payload = {
            "rideId": CREATED_RIDE_ID,
            "driverId": DRIVER_UID,
            "driverName": "Driver User",
            "driverPhone": "+918888877777"
        }
        res = client.post("/rides/accept", json=payload)
        assert res.status_code == 200
    test("POST /rides/accept", test_accept_ride)

    def test_verify_pin():
        payload = {"rideId": CREATED_RIDE_ID, "pin": CREATED_RIDE_OTP, "driverId": DRIVER_UID}
        res = client.post("/rides/verify-pin", json=payload)
        assert res.status_code == 200
    test("POST /rides/verify-pin", test_verify_pin)

    def test_complete_ride():
        payload = {"rideId": CREATED_RIDE_ID, "driverId": DRIVER_UID, "finalFare": 50.0, "driverEarnings": 42.5}
        res = client.post("/rides/complete", json=payload)
        assert res.status_code == 200
    test("POST /rides/complete", test_complete_ride)

    # 9. Extra Features: Rate, Driver Stats, Cancel, SOS, Chat
    def test_rate_ride():
        payload = {"rideId": CREATED_RIDE_ID, "rating": 5.0, "review": "Great safe trip!"}
        res = client.post("/rides/rate", json=payload)
        assert res.status_code == 200
    test("POST /rides/rate (Rate Ride)", test_rate_ride)

    def test_driver_stats():
        res = client.get(f"/driver/stats/{DRIVER_UID}")
        assert res.status_code == 200, f"Got {res.status_code}: {res.text}"
        assert res.json()["completedRides"] >= 1
    test("GET /driver/stats/{driver_id} (Driver Performance Stats)", test_driver_stats)

    def test_sos_trigger():
        payload = {"rideId": CREATED_RIDE_ID, "userId": RIDER_UID, "note": "Test emergency"}
        res = client.post("/rides/sos", json=payload)
        assert res.status_code == 200
    test("POST /rides/sos (Emergency SOS Alert)", test_sos_trigger)

    def test_get_chat():
        res = client.get(f"/rides/{CREATED_RIDE_ID}/chat")
        assert res.status_code == 200
    test("GET /rides/{ride_id}/chat (In-App Chat History)", test_get_chat)

    def test_cancel_ride():
        r = client.post("/rides/create", json={
            "passengerId": RIDER_UID, "passengerName": "Cancel Test",
            "passengerPhone": "+91000", "pickup": {}, "destination": {}
        }).json()["ride"]["id"]
        res = client.post("/rides/cancel", json={"rideId": r, "cancelledBy": "rider", "reason": "Plans changed"})
        assert res.status_code == 200
        assert res.json()["status"] == "CANCELLED"
    test("POST /rides/cancel (Cancel Ride)", test_cancel_ride)

    print("-" * 60)
    print(f"RESULTS: Passed = {results['passed']}, Failed = {results['failed']}")
    if results["issues"]:
        print("ISSUES DETECTED:")
        for issue in results["issues"]:
            print(f" - {issue}")
    print("-" * 60)

if __name__ == "__main__":
    run_tests()
