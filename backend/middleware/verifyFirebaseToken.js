const admin = require('../firebaseAdmin');

// Middleware to verify Firebase ID token sent in Authorization header
// Usage: app.use('/api/some', verifyFirebaseToken, someRouter)
module.exports = async function verifyFirebaseToken(req, res, next) {
  try {
    const authHeader = req.headers.authorization || req.headers.Authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'No Firebase ID token provided' });
    }

    const idToken = authHeader.split('Bearer ')[1];
    if (!idToken) return res.status(401).json({ message: 'Invalid auth header' });

    const decodedToken = await admin.auth().verifyIdToken(idToken);

    // Attach firebase info to request object
    req.firebaseUser = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      claims: decodedToken,
    };

    next();
  } catch (err) {
    console.error('Firebase token verification failed:', err.message || err);
    return res.status(401).json({ message: 'Unauthorized: invalid Firebase token' });
  }
};
