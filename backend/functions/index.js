const https = require('https');
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const express = require('express');
const cors = require('cors');
require('dotenv').config();
const redisClient = require('./redis_client');


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
let latestRideRequest = null;

const app = express();
app.use(cors({ origin: true, credentials: true }));
app.options('*', cors());
app.use(express.json());

const jwt = require('jsonwebtoken');

// Helper to normalize phone queries (handles +91, spaces, 10-digit)
function getPhoneVariants(query) {
  if (!query) return [];
  const raw = String(query).trim();
  const digits = raw.replace(/\D/g, '');
  const last10 = digits.length >= 10 ? digits.slice(-10) : digits;
  const set = new Set();
  set.add(raw);
  if (last10) {
    set.add(last10);
    set.add(`+91${last10}`);
    set.add(`+91 ${last10}`);
    set.add(`0${last10}`);
  }
  return Array.from(set);
}

// POST /auth/signup - Custom JWT-based Signup
app.post('/auth/signup', async (req, res) => {
  try {
    const { username, name, phone, password, email, role = 'rider' } = req.body;
    
    if (!username || !name || !phone || !password) {
      return res.status(400).json({ status: 'error', message: 'Username, Name, Phone and Password are required.' });
    }

    const collectionName = role === 'driver' ? 'drivers' : 'users';
    const phoneVariants = getPhoneVariants(phone);

    // 1. Check if user already exists by username, phone variants, or email
    let existingDoc = null;
    let existingUserSnap = await db.collection(collectionName).where('username', '==', username).limit(1).get();
    if (!existingUserSnap.empty) {
      existingDoc = existingUserSnap.docs[0];
    }

    if (!existingDoc) {
      for (const p of phoneVariants) {
        const snap = await db.collection(collectionName).where('phone', '==', p).limit(1).get();
        if (!snap.empty) {
          existingDoc = snap.docs[0];
          break;
        }
      }
    }

    if (!existingDoc && email && email.trim()) {
      const snap = await db.collection(collectionName).where('email', '==', email.trim()).limit(1).get();
      if (!snap.empty) {
        existingDoc = snap.docs[0];
      }
    }

    // 2. If user exists: check password. If password matches, automatically log in!
    if (existingDoc) {
      const existingData = existingDoc.data();
      const existingUid = existingDoc.id;

      if (!existingData.password || existingData.password === password) {
        const jwtSecret = process.env.JWT_SECRET || 'payano_jwt_secret_key_2026';
        const token = jwt.sign(
          { uid: existingUid, username: existingData.username || username, phone: existingData.phone || phone, role: existingData.role || role }, 
          jwtSecret, 
          { expiresIn: '30d' }
        );
        return res.status(200).json({
          status: 'success',
          message: 'Account already exists. Logged in successfully!',
          token,
          user: existingData
        });
      } else {
        return res.status(400).json({
          status: 'error',
          message: 'An account with this mobile number or email already exists. Please log in with your password.'
        });
      }
    }

    // 3. New user registration
    const uid = 'usr_' + Date.now().toString() + '_' + Math.random().toString(36).substr(2, 5);
    const standardPhone = phoneVariants.find(p => p.startsWith('+91')) || phone;

    let userData;
    const batch = db.batch();

    if (role === 'driver') {
      const driverRef = db.collection('drivers').doc(uid);
      userData = {
        id: 'drv_' + uid,
        userId: uid,
        username,
        name,
        phone: standardPhone,
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
        verificationStatus: 'unverified',
        studentVerificationStatus: 'unverified',
        createdAt: new Date().toISOString(),
      };
      batch.set(driverRef, userData);
    } else {
      const userRef = db.collection('users').doc(uid);
      userData = {
        uid,
        username,
        name,
        phone: standardPhone,
        password,
        email: email || '',
        role: 'rider',
        rating: 5.0,
        walletBalance: 250.0,
        savedLocations: [],
        verificationStatus: 'verified',
        studentVerificationStatus: 'verified',
        profileSetupCompleted: false,
        createdAt: new Date().toISOString(),
      };
      batch.set(userRef, userData);
    }

    await batch.commit();

    const jwtSecret = process.env.JWT_SECRET || 'payano_jwt_secret_key_2026';
    const token = jwt.sign(
      { uid, username, phone: userData.phone, role: userData.role }, 
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

// POST /auth/firebase-login - Verify Firebase ID token using Admin SDK and return JWT + user profile
app.post('/auth/firebase-login', async (req, res) => {
  try {
    const { idToken, role = 'rider' } = req.body;
    if (!idToken) {
      return res.status(400).json({ status: 'error', message: 'idToken is required' });
    }

    // Verify token using Firebase Admin SDK
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const { uid, email, name, picture, phone_number } = decodedToken;

    const collectionName = role === 'driver' ? 'drivers' : 'users';
    const userDocRef = db.collection(collectionName).doc(uid);
    const userSnap = await userDocRef.get();

    let userData;
    if (userSnap.exists) {
      userData = userSnap.data();
      userData.uid = uid;
    } else {
      userData = {
        uid,
        name: name || (email ? email.split('@')[0] : 'Payano User'),
        username: email ? email.split('@')[0] : 'user_' + uid.slice(0, 6),
        email: email || '',
        phone: phone_number || '',
        profileImage: picture || '',
        role,
        rating: 5.0,
        walletBalance: 0.0,
        verificationStatus: 'unverified',
        studentVerificationStatus: 'unverified',
        profileSetupCompleted: false,
        createdAt: new Date().toISOString(),
      };
      await userDocRef.set(userData, { merge: true });
    }

    const jwtSecret = process.env.JWT_SECRET || 'payano_jwt_secret_key_2026';
    const token = jwt.sign(
      { uid, email: userData.email, role: userData.role || role },
      jwtSecret,
      { expiresIn: '30d' }
    );

    return res.status(200).json({
      status: 'success',
      message: 'Authentication successful',
      token,
      user: userData,
    });
  } catch (error) {
    console.error('Firebase Login Error:', error);
    return res.status(401).json({ status: 'error', message: error.message });
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
    const { username, phone, email, password, role = 'rider' } = req.body;
    const loginQuery = (username || phone || email || '').trim();

    if (!loginQuery) {
      return res.status(400).json({ status: 'error', message: 'Username, Phone, or Email is required.' });
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

    // Comprehensive multi-query search
    const phoneVariants = getPhoneVariants(loginQuery);
    let snapshot = await db.collection(collectionName).where('username', '==', loginQuery).limit(1).get();
    
    if (snapshot.empty) {
      for (const p of phoneVariants) {
        const snap = await db.collection(collectionName).where('phone', '==', p).limit(1).get();
        if (!snap.empty) {
          snapshot = snap;
          break;
        }
      }
    }

    if (snapshot.empty && loginQuery.includes('@')) {
      snapshot = await db.collection(collectionName).where('email', '==', loginQuery).limit(1).get();
    }

    if (snapshot.empty) {
      return res.status(404).json({
        status: 'error',
        message: `No ${role === 'driver' ? 'Driver' : 'Passenger'} account found for '${loginQuery}'. Please check role selection or sign up.`
      });
    }

    const userDoc = snapshot.docs[0];
    const userData = userDoc.data();
    const uid = userDoc.id;

    // Validate password
    if (password && userData.password && userData.password !== password) {
      return res.status(401).json({ status: 'error', message: 'Invalid password. Please try again.' });
    }

    // Generate JWT
    const jwtSecret = process.env.JWT_SECRET || 'payano_jwt_secret_key_2026';
    const token = jwt.sign(
      { uid, username: userData.username || loginQuery, phone: userData.phone || '', role: userData.role || role }, 
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
  res.send('Payano Backend API is running correctly! ??');
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
    currency: '?',
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
    latestRideRequest = rideData;
    try {
      if (redisClient && redisClient.exec) {
        redisClient.exec(['PUBLISH', 'drivers_available', JSON.stringify({ event: 'new_ride_request', data: rideData })]);
      }
    } catch (_) {}

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


// Helper to perform HTTPS GET and return parsed JSON
function httpsGetJson(requestUrl) {
  return new Promise((resolve, reject) => {
    https.get(requestUrl, (resp) => {
      let data = '';
      resp.on('data', chunk => data += chunk);
      resp.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(e);
        }
      });
    }).on('error', reject);
  });
}

// GET /places/autocomplete - Proxy to Google Places Autocomplete API
app.get('/places/autocomplete', async (req, res) => {
  try {
    const { input, lat = '11.6756', lng = '78.1470' } = req.query;
    if (!input || !input.trim()) {
      return res.json({ status: 'success', predictions: [] });
    }
    const apiKey = process.env.GOOGLE_MAPS_API_KEY || 'AIzaSyBFtnso4MxBy37IzebKiWq3DtAjYkXov0U';
    const targetUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=' + encodeURIComponent(input) + '&location=' + lat + ',' + lng + '&radius=30000&components=country:in&key=' + apiKey;
    
    const data = await httpsGetJson(targetUrl);
    if (data.status === 'OK' && Array.isArray(data.predictions)) {
      const formatted = data.predictions.map(p => ({
        place_id: p.place_id,
        description: p.description,
        main_text: p.structured_formatting ? p.structured_formatting.main_text : p.description,
        secondary_text: p.structured_formatting ? p.structured_formatting.secondary_text : ''
      }));
      return res.json({ status: 'success', predictions: formatted });
    }
    return res.json({ status: 'success', predictions: [] });
  } catch (error) {
    console.error('Places autocomplete error:', error.message);
    return res.status(500).json({ status: 'error', message: error.message });
  }
});

// GET /places/geocode - Proxy to Google Geocoding API
app.get('/places/geocode', async (req, res) => {
  try {
    const { lat, lng, address, place_id } = req.query;
    const apiKey = process.env.GOOGLE_MAPS_API_KEY || 'AIzaSyBFtnso4MxBy37IzebKiWq3DtAjYkXov0U';
    let targetUrl;

    if (place_id) {
      targetUrl = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=' + place_id + '&fields=geometry,formatted_address&key=' + apiKey;
      const data = await httpsGetJson(targetUrl);
      if (data.result && data.result.geometry && data.result.geometry.location) {
        return res.json({
          status: 'success',
          address: data.result.formatted_address || '',
          location: data.result.geometry.location
        });
      }
    } else if (lat && lng) {
      targetUrl = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=' + lat + ',' + lng + '&key=' + apiKey;
      const data = await httpsGetJson(targetUrl);
      if (data.results && data.results.length > 0) {
        return res.json({
          status: 'success',
          address: data.results[0].formatted_address,
          location: data.results[0].geometry.location
        });
      }
    } else if (address) {
      targetUrl = 'https://maps.googleapis.com/maps/api/geocode/json?address=' + encodeURIComponent(address) + '&key=' + apiKey;
      const data = await httpsGetJson(targetUrl);
      if (data.results && data.results.length > 0) {
        return res.json({
          status: 'success',
          address: data.results[0].formatted_address,
          location: data.results[0].geometry.location
        });
      }
    }

    // Default Sona College of Technology, Salem coordinates fallback
    return res.json({
      status: 'success',
      address: 'Sona College of Technology, Junction Main Road, Salem',
      location: { lat: 11.6756, lng: 78.1470 }
    });
  } catch (error) {
    console.error('Geocode error:', error.message);
    return res.status(500).json({ status: 'error', message: error.message });
  }
});

// GET /routes/directions - Google Routes / Directions proxy
app.get('/routes/directions', async (req, res) => {
  try {
    const { origin, destination } = req.query;
    if (!origin || !destination) {
      return res.status(400).json({ status: 'error', message: 'origin and destination parameters required' });
    }
    const apiKey = process.env.GOOGLE_MAPS_API_KEY || 'AIzaSyBFtnso4MxBy37IzebKiWq3DtAjYkXov0U';
    const targetUrl = 'https://maps.googleapis.com/maps/api/directions/json?origin=' + encodeURIComponent(origin) + '&destination=' + encodeURIComponent(destination) + '&mode=driving&key=' + apiKey;
    const data = await httpsGetJson(targetUrl);
    if (data.status === 'OK' && data.routes && data.routes.length > 0) {
      const leg = data.routes[0].legs[0];
      const distanceKm = Number((leg.distance.value / 1000).toFixed(2));
      const durationMin = Number((leg.duration.value / 60).toFixed(1));
      const overviewPolyline = data.routes[0].overview_polyline ? data.routes[0].overview_polyline.points : '';
      
      return res.json({
        status: 'success',
        distanceKm,
        durationMinutes: durationMin,
        polyline: overviewPolyline,
        startAddress: leg.start_address,
        endAddress: leg.end_address
      });
    }
    return res.json({ status: 'error', message: data.error_message || data.status || 'No route found' });
  } catch (error) {
    console.error('Directions error:', error.message);
    return res.status(500).json({ status: 'error', message: error.message });
  }
});

// GET /rides/latest - Active drivers query this to instantly fetch passenger live location
app.get('/rides/latest', async (req, res) => {
  try {
    if (latestRideRequest) {
      return res.json({ status: 'success', ride: latestRideRequest });
    }
    const snap = await db.collection('rides').where('status', '==', 'SEARCHING').limit(1).get();
    if (!snap.empty) {
      const doc = snap.docs[0];
      return res.json({ status: 'success', ride: { id: doc.id, ...doc.data() } });
    }
    return res.json({ status: 'none', message: 'No active ride requests' });
  } catch (error) {
    return res.status(500).json({ status: 'error', message: error.message });
  }
});

exports.api = functions.https.onRequest(app);

// Allow standalone local server execution (node index.js)
if (require.main === module) {
  const PORT = process.env.PORT || 5000;
  app.listen(PORT, () => {
    console.log(`?? Payano Backend API server running on http://localhost:${PORT}`);
    console.log(`?? Test pricing endpoint: http://localhost:${PORT}/pricing`);
  });
}