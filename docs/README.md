# Payano - Modern Urban Two-Wheeler Mobility & Bike-Taxi Platform

Payano is a complete, production-grade two-wheeler ride-hailing and bike-taxi platform engineered specifically for modern urban commuting. Built using **Flutter** for cross-platform mobile support (iOS, Android) and backed by **Firebase Services** (Auth, Firestore, Cloud Functions, FCM, Storage) with a Node.js API layer.

---

## Key Features

- **Exclusive Two-Wheeler Categories:**
  - 🛵 **Payano Lite:** Compact 100-110cc Scooter for quick short-distance rides.
  - 🏍️ **Payano Moto:** Standard commuter bike for agile traffic navigation.
  - ⚡ **Payano Green EV:** Eco-friendly zero-emission electric scooter options.
  - 🚀 **Payano Priority Express:** Top-rated driver priority pickup.
- **Figma Inspired UI/UX Aesthetic:** Dark slate & electric amber design system, smooth bottom sheets, custom map markers, and interactive micro-animations.
- **Dynamic Fare Engine:** Server-validated fare calculation combining base fare, per-km rate, per-minute rate, surge multipliers, and coupon discounts.
- **Real-Time Ride Tracking & Matching:** Radar sonar searching screen, live map location updates, 4-digit passenger Start OTP verification, and SOS safety integration.
- **Driver App:** Online/offline status toggle, incoming request modal overlay with 15-second circular countdown timer, earnings dashboard, and document verification onboarding.
- **Admin Portal:** Dynamic surge multiplier control, active online driver telemetry, and driver document approval workflow.

---

## Directory Structure

```
payano_new/
├── mobile/             # Flutter Mobile App (Rider + Driver + Admin)
│   ├── lib/
│   │   ├── core/       # Theme, Config, Services, Reusable Widgets
│   │   ├── features/   # Auth, Onboarding, Home, Ride, Driver, Wallet, History, Support, Admin
│   │   ├── routing/    # AppRouter (go_router)
│   │   └── main.dart
│   ├── .env.example
│   └── pubspec.yaml
├── backend/            # Firebase Security Rules, Indexes & Cloud Functions
│   ├── firestore.rules
│   ├── firestore.indexes.json
│   ├── storage.rules
│   ├── functions/      # Node.js Firebase API
│   └── .env.example
└── docs/               # Full Technical Documentation
    ├── SETUP.md
    ├── ARCHITECTURE.md
    ├── DATABASE.md
    └── API.md
```
