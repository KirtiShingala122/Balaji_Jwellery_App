const express = require('express');
const router = express.Router();
const reportController = require('../controllers/reportController');

// GET /api/reports/monthly-sales
router.get('/monthly-sales', reportController.getMonthlySales);

// GET /api/reports/top-products
router.get('/top-products', reportController.getTopProducts);

// GET /api/reports/category-breakdown
router.get('/category-breakdown', reportController.getCategoryBreakdown);

// GET /api/reports/summary
router.get('/summary', reportController.getSummary);

module.exports = router;
