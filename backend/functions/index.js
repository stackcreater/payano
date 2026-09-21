const functions = require('firebase-functions');
const admin = require('firebase-admin');
const express = require('express');
const cors = require('cors');
require('dotenv').config();

let serviceAccount;
try {
  serviceAccount = require('./payano-49f04-firebase-adminsdk-fbsvc-c3c780bc8f.json');
} catch (e) {
  // Service account not found locally, relying on Firebase default credentials
}

if (serviceAccount) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
} else {
  admin.initializeApp();
}

const db = admin.firestore();

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

const jwt = require('jsonwebtoken');

// POST /auth/signup - Custom JWT-based Signup
app.post('/auth/signup', async (req, res) => {
  try {
    const { username, name, phone, password, email, role = 'rider' } = req.body;
    
    if (!username || !name || !phone || !password) {
      return res.status(400).json({ status: 'error', message: 'Username, Name, Phone and Password are required.' });
    }

    const collectionName = role === 'driver' ? 'drivers' : 'users';

    // Check if username already exists in collection
    const existingUser = await db.collection(collectionName).where('username', '==', username).limit(1).get();
    if (!existingUser.empty) {
      return res.status(400).json({ status: 'error', message: 'Username already taken. Please choose another.' });
    }

    // Generate a unique user ID (since we bypassed Firebase Auth on client)
    const uid = 'usr_' + Date.now().toString() + '_' + Math.random().toString(36).substr(2, 5);

    let userData;
    const batch = db.batch();

    if (role === 'driver') {
      const driverRef = db.collection('drivers').doc(uid);
      userData = {
        id: 'drv_' + uid,
        userId: uid,
        username,
        name,
        phone,
        password,
        email: email || '',
        isOnline: true,
        isAvailable: true,
        vehicle: {
          vehicleType: 'Payano Moto',
          registrationNumber: '',
          modelName: '',
          color: 'Black',
        },
        rating: 4.8,
        todayEarnings: 0.0,
        role: 'driver',
        verificationStatus: 'unverified'
      };
      batch.set(driverRef, userData);
    } else {
      const userRef = db.collection('users').doc(uid);
      userData = {
        uid,
        username,
        name,
        phone,
        password,
        email: email || '',
        role: 'rider',
        rating: 5.0,
        walletBalance: 250.0,
        savedLocations: [],
      };
      batch.set(userRef, userData);
    }

    await batch.commit();

    // Generate JWT
    const jwtSecret = process.env.JWT_SECRET || 'payano_jwt_secret_key_2026';
    const token = jwt.sign(
      { uid, username, phone, role: userData.role }, 
      jwtSecret, 
      { expiresIn: '30d' }
    );

    return res.status(201).json({
      status: 'success',
      message: 'Signup successful',
      token,
      user: userData
    });
  } catch (error) {
    console.error('Signup Error:', error);
    return res.status(500).json({ status: 'error', message: error.message });
  }
});

// Middleware to verify JWT token
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Format: Bearer <TOKEN>

  if (!token) {
    return res.status(401).json({ status: 'error', message: 'Access token missing' });
  }

  const jwtSecret = process.env.JWT_SECRET || 'payano_jwt_secret_key_2026';
  jwt.verify(token, jwtSecret, (err, user) => {
    if (err) {
      return res.status(403).json({ status: 'error', message: 'Invalid or expired JWT token' });
    }
    req.user = user;
    next();
  });
};

// POST /auth/login - JWT-based Login for existing users
app.post('/auth/login', async (req, res) => {
  try {
    const { username, phone, password, role = 'rider' } = req.body;
    const loginQuery = username || phone;

    if (!loginQuery) {
      return res.status(400).json({ status: 'error', message: 'Username or Phone is required.' });
    }

    const collectionName = role === 'driver' ? 'drivers' : 'users';
    
    // Check for admin login credentials
    const envAdminUser = process.env.ADMIN_USERNAME || 'admin';
    const envAdminPass = process.env.ADMIN_PASSWORD || 'Admin@5645';
    if (loginQuery === envAdminUser && password === envAdminPass) {
      if (role !== 'driver') {
        return res.status(400).json({ status: 'error', message: 'Admin login is only allowed under Driver tab.' });
      }
      const adminUser = {
        uid: 'admin_001',
        username: 'admin',
        name: 'Payano Admin',
        email: 'admin@payano.in',
        role: 'admin',
        rating: 5.0,
        walletBalance: 0.0,
        verificationStatus: 'verified',
        studentVerificationStatus: 'verified',
        profileSetupCompleted: true,
      };
      const jwtSecret = process.env.JWT_SECRET || 'payano_jwt_secret_key_2026';
      const token = jwt.sign({ uid: adminUser.uid, username: 'admin', role: 'admin' }, jwtSecret, { expiresIn: '30d' });
      return res.status(200).json({
        status: 'success',
        message: 'Admin login successful',
        token,
        user: adminUser,
      });
    }
    
    // Check by username first, fallback to phone
    let snapshot = await db.collection(collectionName).where('username', '==', loginQuery).limit(1).get();
    if (snapshot.empty) {
      snapshot = await db.collection(collectionName).where('phone', '==', loginQuery).limit(1).get();
    }

    if (snapshot.empty) {
      return res.status(404).json({ status: 'error', message: `No ${role === 'driver' ? 'Driver' : 'Passenger'} account found for '${loginQuery}'. Please check role selection or sign up.` });
    }

    const userDoc = snapshot.docs[0];
    const userData = userDoc.data();
    const uid = userDoc.id;

    // Validate password if user has password set
    if (password && userData.password && userData.password !== password) {
      return res.status(401).json({ status: 'error', message: 'Invalid password. Please try again.' });
    }

    // Generate JWT
    const jwtSecret = process.env.JWT_SECRET || 'payano_jwt_secret_key_2026';
    const token = jwt.sign(
      { uid, username: userData.username || username, phone: userData.phone || phone, role: userData.role || role }, 
      jwtSecret, 
      { expiresIn: '30d' }
    );

    return res.status(200).json({
      status: 'success',
      message: 'Login successful',
      token,
      user: userData
    });
  } catch (error) {
    console.error('Login Error:', error);
    return res.status(500).json({ status: 'error', message: error.message });
  }
});

// GET /auth/me - Protected route to verify JWT and get user profile
app.get('/auth/me', authenticateToken, async (req, res) => {
  try {
    const { uid, role } = req.user;
    const collectionName = role === 'driver' ? 'drivers' : 'users';
    const doc = await db.collection(collectionName).doc(uid).get();

    if (!doc.exists) {
      return res.status(404).json({ status: 'error', message: 'User not found' });
    }

    return res.json({
      status: 'success',
      user: doc.data()
    });
  } catch (error) {
    return res.status(500).json({ status: 'error', message: error.message });
  }
});

// Root Endpoint
app.get('/', (req, res) => {
  res.send('Payano Backend API is running correctly! 🚀');
});

// 2-Wheeler Category Rates (INR)
const TWO_WHEELER_CONFIG = {
  lite: { baseFare: 15, perKm: 7.5, perMin: 1.0, minimumFare: 25, platformFee: 5 },
  moto: { baseFare: 20, perKm: 9.0, perMin: 1.2, minimumFare: 30, platformFee: 5 },
  ev: { baseFare: 18, perKm: 8.0, perMin: 1.0, minimumFare: 25, platformFee: 5 },
  express: { baseFare: 30, perKm: 12.0, perMin: 1.5, minimumFare: 45, platformFee: 5 },
};

// GET /api/pricing
app.get('/pricing', (req, res) => {
  return res.json({
    status: 'success',
    currency: '₹',
    categories: TWO_WHEELER_CONFIG,
  });
});

// POST /api/fare/calculate
app.post('/fare/calculate', (req, res) => {
  const { category = 'moto', distanceKm = 5.0, durationMins = 15.0, surgeMultiplier = 1.0, promoDiscount = 0.0 } = req.body;

  const cfg = TWO_WHEELER_CONFIG[category] || TWO_WHEELER_CONFIG.moto;
  let rawFare = cfg.baseFare + (distanceKm * cfg.perKm) + (durationMins * cfg.perMin) + cfg.platformFee;
  rawFare = rawFare * surgeMultiplier;
  
  let finalFare = rawFare - promoDiscount;
  if (finalFare < cfg.minimumFare) finalFare = cfg.minimumFare;

  return res.json({
    status: 'success',
    category,
    distanceKm,
    durationMins,
    estimatedFare: Math.round(finalFare),
    breakdown: {
      baseFare: cfg.baseFare,
      distanceFee: Math.round(distanceKm * cfg.perKm),
      timeFee: Math.round(durationMins * cfg.perMin),
      platformFee: cfg.platformFee,
      surgeMultiplier,
      discount: promoDiscount,
    },
  });
});

// POST /api/rides/create
app.post('/rides/create', async (req, res) => {
  try {
    const { passengerId, passengerName, passengerPhone, pickup, destination, category = 'moto' } = req.body;

    const rideRef = db.collection('rides').doc();
    const rideData = {
      id: rideRef.id,
      passengerId,
      passengerName,
      passengerPhone,
      pickup,
      destination,
      vehicleType: category,
      status: 'SEARCHING',
      startOtp: Math.floor(1000 + Math.random() * 9000).toString(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await rideRef.set(rideData);

    return res.status(201).json({
      status: 'success',
      message: 'Ride request created successfully',
      ride: rideData,
    });
  } catch (error) {
    return res.status(500).json({ status: 'error', message: error.message });
  }
});

// POST /driver/register - Store driver registration details in DB
app.post('/driver/register', async (req, res) => {
  try {
    const {
      userId,
      name,
      phone,
      email,
      studentVerified = true,
      vehicleType = 'Scooter',
      makeModel = 'Honda Activa 6G',
      registrationNumber = '',
      color = 'Blue',
      ownership = 'I own this vehicle',
      documents = {}
    } = req.body;

    if (!userId) {
      return res.status(400).json({ status: 'error', message: 'userId is required' });
    }

    const regId = 'reg_' + Date.now() + '_' + Math.random().toString(36).substr(2, 4);

    const registrationData = {
      id: regId,
      userId,
      name: name || 'Payano Driver',
      phone: phone || '',
      email: email || '',
      studentVerified: Boolean(studentVerified),
      vehicleType,
      makeModel,
      registrationNumber,
      color,
      ownership,
      documents: {
        drivingLicence: documents.drivingLicence || { docNumber: 'DL123456789012', status: 'Uploaded' },
        rc: documents.rc || { docNumber: registrationNumber || 'TN30AB4582', status: 'Uploaded' },
        insurance: documents.insurance || { docNumber: 'Policy No. 1234567890', status: 'Uploaded' }
      },
      status: 'PENDING_VERIFICATION',
      submittedAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    const batch = db.batch();

    // 1. Store application detail in driver_registrations collection
    const regRef = db.collection('driver_registrations').doc(userId);
    batch.set(regRef, registrationData, { merge: true });

    // 2. Update/create driver profile doc in drivers collection
    const driverRef = db.collection('drivers').doc(userId);
    const driverData = {
      id: 'drv_' + userId,
      userId,
      name: name || 'Payano Driver',
      phone: phone || '',
      email: email || '',
      isOnline: true,
      isAvailable: true,
      verificationStatus: 'pending',
      rating: 4.8,
      todayEarnings: 0.0,
      role: 'driver',
      vehicle: {
        vehicleType,
        registrationNumber,
        modelName: makeModel,
        color,
        ownership,
        helmetType: 'Standard ISI Helmet'
      },
      registration: {
        registrationId: regId,
        status: 'PENDING_VERIFICATION',
        submittedAt: registrationData.submittedAt
      }
    };
    batch.set(driverRef, driverData, { merge: true });

    await batch.commit();

    return res.status(200).json({
      status: 'success',
      message: 'Driver registration application submitted successfully!',
      registration: registrationData,
      driver: driverData
    });
  } catch (error) {
    console.error('Driver Registration Error:', error);
    return res.status(500).json({ status: 'error', message: error.message });
  }
});

// GET /driver/registration/:userId - Retrieve driver application details
app.get('/driver/registration/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const doc = await db.collection('driver_registrations').doc(userId).get();
    if (!doc.exists) {
      return res.status(404).json({ status: 'error', message: 'Registration not found' });
    }
    return res.json({ status: 'success', registration: doc.data() });
  } catch (error) {
    return res.status(500).json({ status: 'error', message: error.message });
  }
});

exports.api = functions.https.onRequest(app);

// Allow standalone local server execution (node index.js)
if (require.main === module) {
  const PORT = process.env.PORT || 5000;
  app.listen(PORT, () => {
    console.log(`🚀 Payano Backend API server running on http://localhost:${PORT}`);
    console.log(`👉 Test pricing endpoint: http://localhost:${PORT}/pricing`);
  });
}
