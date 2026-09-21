# Payano Architecture & Design System

## High-Level System Architecture

```mermaid
graph TD
    A[Flutter App - Rider/Driver/Admin] -->|Riverpod State & go_router| B(Presentation Layer)
    B --> C(Domain & State Notifiers)
    C --> D(Repository Layer)
    D -->|Firebase SDK / Dio| E(Firebase Auth / Firestore / Storage)
    D -->|HTTPS REST| F(Firebase Cloud Functions API)
    F -->|Google Maps API| G(Directions & Places Service)
    F -->|Payment Gateway| H(Razorpay / UPI Integration)
```

## Clean Architecture Layers

1. **Presentation Layer (`lib/features/*/presentation`)**: Flutter UI widgets, custom bottom sheets, interactive maps, and responsive layouts built with Material 3.
2. **Domain Layer (`lib/features/*/domain`)**: State Notifiers (`RideNotifier`, `RideState`), Business Rules, and State Machine logic.
3. **Data & Service Layer (`lib/core/services`)**: `AuthService`, `LocationService`, `MapsService`, Firebase Firestore bindings, and Local Storage (`flutter_secure_storage`).

## Ride State Machine

```
[REQUESTED] ──> [SEARCHING] ──> [DRIVER_ASSIGNED] ──> [DRIVER_ARRIVING] ──> [DRIVER_ARRIVED] ──> [TRIP_STARTED] ──> [TRIP_COMPLETED]
     │               │                 │                    │                   │
     └──[CANCELLED]──┴───[CANCELLED]───┴────[CANCELLED]─────┴───[CANCELLED]─────┘
```
