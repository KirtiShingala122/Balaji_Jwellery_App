const express = require('express');
const router = express.Router();
const { getAllBills, getBillById, addBill, deleteBill } = require('../controllers/billController');

router.get('/', getAllBills);
router.get('/:id', getBillById);
router.post('/', addBill);
router.delete('/:id', deleteBill);

module.exports = router;
