# Payano REST API Endpoints Specification

Base URL: `https://us-central1-payano-app.cloudfunctions.net/api`

---

## Endpoints

### 1. Get Two-Wheeler Category Rates
- **GET** `/pricing`
- **Response:**
  ```json
  {
    "status": "success",
    "currency": "₹",
    "categories": {
      "lite": { "baseFare": 15, "perKm": 7.5, "perMin": 1.0 },
      "moto": { "baseFare": 20, "perKm": 9.0, "perMin": 1.2 },
      "ev": { "baseFare": 18, "perKm": 8.0, "perMin": 1.0 },
      "express": { "baseFare": 30, "perKm": 12.0, "perMin": 1.5 }
    }
  }
  ```

### 2. Calculate Server-Verified Fare
- **POST** `/fare/calculate`
- **Body:**
  ```json
  {
    "category": "moto",
    "distanceKm": 6.5,
    "durationMins": 18.0,
    "surgeMultiplier": 1.2,
    "promoDiscount": 25.0
  }
  ```
- **Response:**
  ```json
  {
    "status": "success",
    "category": "moto",
    "estimatedFare": 45,
    "breakdown": {
      "baseFare": 20,
      "distanceFee": 58,
      "timeFee": 21,
      "platformFee": 5,
      "surgeMultiplier": 1.2,
      "discount": 25
    }
  }
  ```

### 3. Create Two-Wheeler Ride Request
- **POST** `/rides/create`
- **Body:**
  ```json
  {
    "passengerId": "usr_9042",
    "passengerName": "Rahul Sharma",
    "passengerPhone": "+91 98765 43210",
    "pickup": { "address": "MG Road", "latitude": 12.9716, "longitude": 77.5946 },
    "destination": { "address": "Koramangala", "latitude": 12.9352, "longitude": 77.6245 },
    "category": "moto"
  }
  ```
