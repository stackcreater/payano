# Payano — Backend (Firebase Cloud Functions + Express API)

Two-wheeler ride-booking backend built on Firebase Cloud Functions with an Express API layer for pricing, fare calculation, and ride creation.

## Folder layout
```
backend/
  functions/
    index.js                          # Express API + Firebase Functions export
    package.json
    payano-*-firebase-adminsdk-*.json # Service account (NEVER commit)
  .env                                # Local secrets (NEVER commit)
  .env.example                        # Template
  firestore.rules
  firestore.indexes.json
  storage.rules
firebase.json                         # Firebase project config (repo root)
```

## Quick start (local development)

```powershell
cd backend/functions
npm install
npm start
```

This runs Express on `http://localhost:5000`.

Test:
```powershell
curl http://localhost:5000/pricing
```

## Endpoints

- `GET  /pricing` — Returns two-wheeler category rates.
- `POST /fare/calculate` — Computes fare. Body: `{ category, distanceKm, durationMins, surgeMultiplier, promoDiscount }`.
- `POST /rides/create` — Creates a ride document in Firestore. Body: `{ passengerId, passengerName, passengerPhone, pickup, destination, category }`.

## Firebase emulator

```powershell
npm install -g firebase-tools
firebase login
cd backend/functions
npm run serve
```

## Deploy

```powershell
cd backend/functions
npm run deploy
```

## Security notes

- The service account JSON file is **never** committed. It is listed in `.gitignore`.
- `.env` is local-only. Production secrets should be set via `firebase functions:secrets:set`.
- If a service account key is ever exposed publicly, **immediately delete the key** in Google Cloud Console → IAM & Admin → Service Accounts, then generate a new one.
