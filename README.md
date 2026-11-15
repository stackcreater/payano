# Payano — Modern Two-Wheeler Mobility & Bike-Taxi Platform

**Payano** is a full-stack urban two-wheeler ride-hailing and bike-taxi platform engineered for modern urban commuting. It features cross-platform mobile apps for Riders and Driver-Partners, dynamic surge pricing, real-time driver telemetry, secure 4-digit start OTPs, in-app wallet management, and Razorpay payment integration.

---

## 📑 Core Documentation

- 📘 **[Full App Explanation & Operational Terms of Use (APP_EXPLANATION.md)](docs/APP_EXPLANATION.md)**: End-to-end user journeys (Rider, Driver, Admin), Razorpay payment architecture, and full terms & conditions.
- 📱 **[Mobile App Guide (mobile/README.md)](mobile/README.md)**: Setup, architecture, and feature modules for the Flutter application.
- 📐 **[System Architecture (docs/ARCHITECTURE.md)](docs/ARCHITECTURE.md)**: Clean architecture, Riverpod state management, and ride state machine.
- 🗄️ **[Database Specification (docs/DATABASE.md)](docs/DATABASE.md)**: Cloud Firestore schemas for users, drivers, rides, and transactions.
- 🌐 **[REST API Specification (docs/API.md)](docs/API.md)**: Cloud Functions and backend endpoints.

---

## 🏗️ Repository Layout

```
payano/
├── mobile/             # Flutter Cross-Platform Application (Rider + Driver + Admin)
├── backend/            # Firebase Functions, Redis Telemetry, and Python API
│   ├── functions/      # Node.js Firebase Cloud Functions
│   └── main.py         # Python FastAPI & Redis matching service
└── docs/               # System documentation & Terms of Use
```

