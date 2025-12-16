const express = require('express');
const router = express.Router();
const {
    getAllCustomers,
    getCustomerById,
    addCustomer,
    updateCustomer,
    deleteCustomer,
    searchCustomers,
} = require('../controllers/customerController');

router.get('/', getAllCustomers);
router.get('/search', searchCustomers);
router.get('/:id', getCustomerById);
router.post('/', addCustomer);
router.put('/:id', updateCustomer);
router.delete('/:id', deleteCustomer);

module.exports = router;
