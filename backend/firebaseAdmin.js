const admin = require('firebase-admin');
const path = require('path');

// Load service account key file from project (already present in backend/)
const serviceAccountPath = path.join(__dirname, 'balaji-imitation-firebase-adminsdk-fbsvc-09bd2e0cec.json');

try {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccountPath),
  });
  console.log('Firebase Admin initialized');
} catch (err) {
  console.warn('Firebase Admin initialization failed (maybe already initialized):', err.message);
}

module.exports = admin;
