const express = require('express');
const router = express.Router();
const {
    getAllProducts,
    getProductById,
    addProduct,
    updateProduct,
    deleteProduct,
    getLowStockProducts
} = require('../controllers/productController');

router.get('/', getAllProducts);
router.get('/low-stock', getLowStockProducts);
router.get('/:id', getProductById);
router.post('/', addProduct);
router.put('/:id', updateProduct);
router.delete('/:id', deleteProduct);

module.exports = router;
