const express = require('express');
const router = express.Router();
const { getAllBills, getBillById, addBill } = require('../controllers/billController');

router.get('/', getAllBills);
router.get('/:id', getBillById);
router.post('/', addBill);

module.exports = router;
