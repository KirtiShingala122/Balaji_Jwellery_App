const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');

// POST /api/chat  — send a message to the AI assistant
router.post('/', chatController.chat);

module.exports = router;
