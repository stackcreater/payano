# Payano Setup & Execution Guide

Follow these exact steps to configure and launch the Payano mobile application and backend services.

---

## 1. Environment Variables Configuration

Copy `.env.example` to `.env` in the `mobile/` directory and paste your API keys:

```bash
cd mobile
cp .env.example .env
```

### Mobile (`mobile/.env`)
Edit `mobile/.env` with your real keys:
```env
GOOGLE_MAPS_API_KEY=AIzaSy_YOUR_REAL_GOOGLE_MAPS_KEY
FIREBASE_API_KEY=AIzaSy_YOUR_REAL_FIREBASE_KEY
FIREBASE_PROJECT_ID=payano-app
RAZORPAY_KEY_ID=rzp_test_YOUR_KEY
```

### Backend (`backend/.env`)
Edit `backend/.env` with your JWT secret and backend credentials:
```env
PORT=5000
NODE_ENV=development
JWT_SECRET=payano_jwt_secret_key_2026
```

> **Tip: How to generate a strong random JWT Secret Key**
> You can generate a cryptographically secure 256-bit JWT secret using Node.js or OpenSSL:
> ```bash
> # Using Node.js
> node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
>
> # Or using OpenSSL
> openssl rand -hex 32
> ```
---

## 2. Flutter Mobile Application Execution

Ensure Flutter 3.x+ is installed on your system.

```bash
# Navigate to mobile directory
cd mobile

# Fetch dependencies
flutter pub get

# Run on connected device / emulator
flutter run
```

---

## 3. Firebase Backend & Functions Setup

```bash
# Navigate to backend functions directory
cd backend/functions

# Install npm dependencies
npm install

# Deploy security rules & functions (requires Firebase CLI)
firebase deploy --only firestore:rules,storage:rules,functions
```
