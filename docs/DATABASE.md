# Payano Database Schema Specification (Cloud Firestore)

## Collections

### 1. `users`
```json
{
  "uid": "usr_9042",
  "phone": "+91 98765 43210",
  "name": "Rahul Sharma",
  "email": "rahul.s@payano.in",
  "role": "rider",
  "rating": 5.0,
  "walletBalance": 250.0,
  "savedLocations": [
    {
      "id": "loc_home",
      "label": "Home",
      "address": "Indiranagar 100ft Road, Bengaluru",
      "latitude": 12.9784,
      "longitude": 77.6408
    }
  ],
  "createdAt": "2026-08-29T10:00:00Z"
}
```

### 2. `drivers`
```json
{
  "id": "drv_driver_1",
  "userId": "usr_driver_1",
  "name": "Ramesh Kumar",
  "phone": "+91 98450 12345",
  "isOnline": true,
  "isAvailable": true,
  "latitude": 12.9716,
  "longitude": 77.5946,
  "vehicle": {
    "vehicleType": "Payano Moto",
    "registrationNumber": "KA-01-EQ-5432",
    "modelName": "TVS Raider 125",
    "color": "Electric Yellow"
  },
  "verificationStatus": "verified",
  "rating": 4.9,
  "totalRides": 890,
  "todayEarnings": 1420.0
}
```

### 3. `rides`
```json
{
  "id": "ride_17000000",
  "passengerId": "usr_9042",
  "driverId": "drv_driver_1",
  "vehicleType": "moto",
  "pickup": {
    "address": "MG Road Metro Station, Bengaluru",
    "latitude": 12.9716,
    "longitude": 77.5946
  },
  "destination": {
    "address": "Koramangala 4th Block, Bengaluru",
    "latitude": 12.9352,
    "longitude": 77.6245
  },
  "distanceKm": 6.5,
  "durationMinutes": 18.0,
  "estimatedFare": 45.0,
  "finalFare": 45.0,
  "status": "TRIP_COMPLETED",
  "startOtp": "4821",
  "paymentMethod": "UPI",
  "isPaid": true,
  "createdAt": "2026-08-29T10:15:00Z"
}
```
