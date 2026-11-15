# Payano Mobile App

**Payano** is a modern, production-grade urban two-wheeler ride-booking and bike-taxi mobile application engineered with Flutter. It provides an on-demand, cost-effective, and agile urban transit solution featuring real-time telemetry, 4-digit start OTPs, in-app wallet management, and Razorpay payment integration.

---

## 📖 Complete Documentation & Terms of Use

For the complete technical architecture, end-to-end user workflows, Razorpay payment lifecycle, and official operational terms of use, please refer to:
👉 **[Full App Explanation & Operational Conditions (docs/APP_EXPLANATION.md)](../docs/APP_EXPLANATION.md)**

---

## 🚀 Core Features

- **Multi-Category Two-Wheeler Options:**
  - 🛵 **Payano Lite:** Budget 100–110cc commuter scooters for short distances.
  - 🏍️ **Payano Moto:** Agile standard commuter motorcycles for traffic navigation.
  - ⚡ **Payano Green EV:** Eco-friendly electric scooters with zero carbon emissions.
  - 🚀 **Payano Priority Express:** Top-rated drivers for priority pickup.
- **Rider App Features:**
  - Live GPS location search with Google Places autocomplete.
  - Real-time driver matching with dynamic radar sonar animation.
  - Turn-by-turn map tracking with live driver marker movements.
  - Secure 4-digit ride Start-OTP verification.
  - SOS emergency button with instant alert broadcast.
  - In-app Wallet & Razorpay online payment integration (UPI, Cards, Netbanking).
  - Student verification program for collegiate discounts.
- **Driver-Partner Features:**
  - Online/Offline toggle with background GPS location broadcasting.
  - Incoming ride request modal with a 15-second countdown timer.
  - Start-OTP verification input to initiate rides.
  - Real-time earnings dashboard with daily, weekly, and ride breakdown charts.
  - Driver onboarding & document submission (License, RC, Insurance).
- **Admin Portal:**
  - Real-time driver telemetry monitoring.
  - Dynamic surge multiplier controls.
  - Driver document verification & approval workflows.

---

## 🛠️ Tech Stack

- **Framework:** Flutter 3.x (Dart 3.2+)
- **State Management:** Riverpod 2.5
- **Navigation:** `go_router 14.6`
- **Mapping:** `maplibre_gl` / `google_maps_flutter`
- **Backend:** Firebase Authentication, Cloud Firestore, Cloud Storage, Cloud Functions
- **Real-time Services:** WebSockets & Redis Geospatial Querying
- **Payments:** Razorpay SDK (Cards, UPI, Netbanking, Wallet top-up)

---

## 📂 Project Structure

```
mobile/
├── lib/
│   ├── core/                  # Theme, Config, Network, WebSocket & Location Services
│   │   ├── services/          # AuthService, LocationService, WebSocketLocationService
│   │   └── theme/             # Dark slate & electric amber color palette
│   ├── features/              # Feature modules
│   │   ├── admin/             # Admin Dashboard & Fleet Telemetry
│   │   ├── auth/              # Login, Signup, OTP, Profile Setup, Student Verification
│   │   ├── driver/            # Driver Home, Onboarding, Documents, Earnings, Rides
│   │   ├── history/           # Completed & Cancelled Ride History
│   │   ├── home/              # Interactive Map & Location Search
│   │   ├── notifications/     # Push & In-App Alerts
│   │   ├── onboarding/        # Welcome carousel & Feature introduction
│   │   ├── profile/           # User Profile & Settings
│   │   ├── ride/              # Radar Searching, Active Ride, Details, Completed
│   │   ├── support/           # Help Center, FAQ & Ticket Submission
│   │   ├── tracking/          # Live Passenger & Driver Tracking Screens
│   │   └── wallet/            # In-App Wallet, Add Money, Payment Methods, Razorpay
│   ├── routing/               # Centralized AppRouter (go_router)
│   └── main.dart              # Application Entry Point
├── assets/                    # Map styles, icons, and illustrations
├── .env                       # Environment variables (API Keys, Firebase configs)
└── pubspec.yaml               # Flutter dependencies
```

---

## 📱 Getting Started

### 1. Prerequisites
- Flutter SDK `>=3.2.0 <4.0.0`
- Android Studio / VS Code with Flutter extension
- Firebase project configured with `google-services.json`

### 2. Environment Setup
Copy `.env.example` to `.env` inside `mobile/` and provide your API keys:
```env
GOOGLE_MAPS_API_KEY=your_google_maps_key
RAZORPAY_KEY_ID=your_razorpay_key_id
API_BASE_URL=https://your-cloud-functions-url.com
```

### 3. Run the App
```bash
flutter pub get
flutter run
```
