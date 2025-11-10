const express = require('express');
const router = express.Router();
const { register, login, verifyToken } = require('../controllers/authController');

// Public routes
router.post('/register', register);
router.post('/login', login);

// Example of a protected route (test only)
router.get('/protected', verifyToken, (req, res) => {
    res.json({ message: `Hello, ${req.user.username}! Token is valid.` });
});

module.exports = router;
