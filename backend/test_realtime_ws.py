"""
Realtime WebSocket and High-Level Feature Test Suite for Payano FastAPI Backend
"""

import sys
import os
import json
import asyncio
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def run_realtime_tests():
    print("=" * 60)
    print("RUNNING REALTIME WEBSOCKET & FEATURE TEST SUITE")
    print("=" * 60)

    # 1. Create a ride first
    ride_res = client.post("/rides/create", json={
        "passengerId": "usr_realtime_1",
        "passengerName": "Realtime Tester",
        "passengerPhone": "+919876543210",
        "pickup": {"address": "Main Gate", "latitude": 12.971, "longitude": 77.594},
        "destination": {"address": "Library", "latitude": 12.978, "longitude": 77.599},
        "category": "moto"
    })
    assert ride_res.status_code == 201
    ride_id = ride_res.json()["ride"]["id"]
    print(f"  ✅ Created Ride for Realtime Test: {ride_id}")

    # 2. Test Driver Channel WebSocket (/ws/drivers)
    print("  🔄 Testing /ws/drivers WebSocket connection...")
    with client.websocket_connect("/ws/drivers") as ws_driver:
        # Ping check
        ws_driver.send_json({"type": "ping"})
        msg = ws_driver.receive_json()
        assert msg.get("event") == "pong"
        print("  ✅ Driver WS Ping -> Pong OK")

        # Driver accepts ride via WS
        ws_driver.send_json({
            "type": "accept_ride",
            "rideId": ride_id,
            "driverId": "drv_realtime_99",
            "driverName": "Speedy Rider",
            "driverPhone": "+919988776655"
        })
        print("  ✅ Driver WS accept_ride sent")

    # Verify DB updated status to DRIVER_ASSIGNED
    ride_check = client.get(f"/rides/{ride_id}").json()["ride"]
    assert ride_check.get("status") == "DRIVER_ASSIGNED"
    assert ride_check.get("driverId") == "drv_realtime_99"
    print(f"  ✅ Verified Ride DB updated to DRIVER_ASSIGNED with driverId {ride_check.get('driverId')}")

    # 3. Test Ride Tracking Channel WebSocket (/ws/ride/{ride_id})
    print(f"  🔄 Testing /ws/ride/{ride_id} WebSocket connection...")
    with client.websocket_connect(f"/ws/ride/{ride_id}") as ws_ride:
        # Send location telemetry from driver
        ws_ride.send_json({
            "type": "location",
            "driverId": "drv_realtime_99",
            "lat": 12.9725,
            "lng": 77.5955,
            "heading": 180.0,
            "speed": 35.0
        })

        # Expect broadcast back
        received_event = ws_ride.receive_json()
        assert received_event.get("event") == "driver_location_updated"
        loc = received_event.get("location", {})
        assert loc.get("latitude") == 12.9725
        assert loc.get("longitude") == 77.5955
        print("  ✅ WS Realtime Driver Location Telemetry Broadcast OK")

        # Send status update (e.g. ARRIVED)
        ws_ride.send_json({
            "type": "status",
            "status": "DRIVER_ARRIVED"
        })
        received_status = ws_ride.receive_json()
        assert received_status.get("event") == "ride_status_updated"
        assert received_status.get("status") == "DRIVER_ARRIVED"
        print("  ✅ WS Realtime Status Update (DRIVER_ARRIVED) OK")

    print("=" * 60)
    print("REALTIME WEBSOCKET TESTING PASSED 100%!")
    print("=" * 60)

if __name__ == "__main__":
    run_realtime_tests()
