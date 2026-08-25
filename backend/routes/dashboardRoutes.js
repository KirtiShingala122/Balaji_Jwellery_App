const express = require('express');
const router = express.Router();
const { getSummary } = require('../controllers/dashboardController');
// Optional: Firebase verification middleware (protect route if desired)
// const verifyFirebaseToken = require('../middleware/verifyFirebaseToken');

// Public summary route (existing behavior)
router.get('/summary', getSummary);

// Example protected route that requires a valid Firebase ID token in `Authorization: Bearer <token>`
const verifyFirebaseToken = require('../middleware/verifyFirebaseToken');
router.get('/summary-protected', verifyFirebaseToken, (req, res) => {
	// req.firebaseUser will have `uid` and `email` after verification
	const fb = req.firebaseUser || {};
	// You can still call existing controller and pass firebase info if needed
	return getSummary(req, res);
});

module.exports = router;
