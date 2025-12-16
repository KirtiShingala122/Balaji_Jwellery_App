const express = require('express');
const router = express.Router();
const {
    getAllProducts,
    getProductById,
    addProduct,
    updateProduct,
    deleteProduct,
    getLowStockProducts,
    upload, 
    getProductByCode 
} = require('../controllers/productController');

router.get('/', getAllProducts);
router.get('/low-stock', getLowStockProducts);
router.get('/code/:code', getProductByCode);
router.get('/:id', getProductById);
router.post('/', upload.single('image'), addProduct);
router.put('/:id', upload.single('image'), updateProduct);
router.delete('/:id', deleteProduct);

module.exports = router;