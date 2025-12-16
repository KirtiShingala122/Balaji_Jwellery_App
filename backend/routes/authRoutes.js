const express = require('express');
const router = express.Router();
const {
    register,
    login,
    verifyToken,
    changePassword,
    updateProfile,
} = require('../controllers/authController');

// Public routes
router.post('/register', register);
router.post('/login', login);

// Protected routes
router.put('/change-password', verifyToken, changePassword);
router.put('/profile', verifyToken, updateProfile);

module.exports = router;
